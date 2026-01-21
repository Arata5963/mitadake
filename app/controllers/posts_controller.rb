# app/controllers/posts_controller.rb
# 投稿（YouTube動画）に関するコントローラー
# - 動画一覧・検索・フィルター表示
# - 動画とアクションプランの同時作成
# - AI提案機能
class PostsController < ApplicationController
  before_action :authenticate_user!, except: [
    :index, :show, :autocomplete, :youtube_search,
    :find_or_create, :recent, :convert_to_youtube_title, :suggest_action_plans
  ]
  before_action :set_post, only: [ :show, :edit, :update, :destroy ]
  before_action :check_has_entries, only: [ :edit, :update, :destroy ]

  # ===== 一覧・詳細 =====

  # 投稿一覧（トップページ）
  # 未ログイン: ランディングページ表示
  # ログイン済み: セクション別表示 or フィルター表示
  def index
    unless user_signed_in?
      render_landing_page
      return
    end

    @q = Post.ransack(params[:q])
    base_scope = @q.result(distinct: true).includes(:achievements, :post_entries)

    if params[:user_id].present?
      load_user_filtered_posts(base_scope)
    elsif params[:channel].present?
      load_channel_filtered_posts(base_scope)
    else
      load_section_data
    end

    respond_to do |format|
      format.html
      format.turbo_stream { render_posts_page }
    end
  end

  # 最近の投稿一覧ページ
  def recent
    @posts = Post.with_entries.recent.page(params[:page]).per(20)
  end

  def show
  end

  # ===== 投稿作成 =====

  # 新規投稿ページ
  def new
    # 認証はbefore_actionで実施済み
  end

  # YouTube URLから投稿を検索または作成
  def find_or_create
    youtube_url = params[:youtube_url]

    if youtube_url.blank?
      render json: { success: false, error: "URLが必要です" }, status: :unprocessable_entity
      return
    end

    @post = Post.find_or_create_by_video(youtube_url: youtube_url)

    if @post
      render json: { success: true, post_id: @post.id, url: post_path(@post) }
    else
      render json: { success: false, error: "動画の情報を取得できませんでした" }, status: :unprocessable_entity
    end
  end

  # 動画とアクションプランを同時に作成
  def create_with_action
    # バリデーション
    error = validate_create_with_action_params
    if error
      render json: { success: false, error: error[:message] }, status: error[:status]
      return
    end

    # 動画を検索または作成
    @post = Post.find_or_create_by_video(youtube_url: params[:youtube_url])
    unless @post
      render json: { success: false, error: "動画の情報を取得できませんでした" }, status: :unprocessable_entity
      return
    end

    # アクションプランを作成
    @entry = build_post_entry(@post)

    if @entry.save
      render json: { success: true, post_id: @post.id, entry_id: @entry.id, url: post_path(@post) }
    else
      render json: { success: false, error: @entry.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end
  end

  # ===== 投稿編集・削除 =====

  def edit
  end

  def update
    if @post.update(post_params)
      redirect_to @post, notice: t("posts.update.success")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @post.entries_by_user(current_user).destroy_all

    # 他にエントリーがなければ投稿自体も削除
    @post.destroy if @post.post_entries.empty?

    redirect_to posts_path, notice: "エントリーを削除しました"
  end

  # ===== 検索API =====

  # 投稿タイトル・チャンネル名のオートコンプリート
  def autocomplete
    query = params[:q].to_s.strip
    @suggestions = query.length >= 2 ? search_suggestions(query) : []
    render layout: false
  end

  # YouTube動画を検索
  def youtube_search
    query = params[:q].to_s.strip
    @videos = query.length >= 2 ? YoutubeService.search_videos(query, max_results: 8) : []

    respond_to do |format|
      format.json { render json: @videos }
      format.html { render layout: false }
    end
  end

  # 既存の投稿を検索（アクションプランがあるもののみ）
  def search_posts
    query = params[:q].to_s.strip
    results = query.length >= 2 ? search_existing_posts(query) : []
    render json: results
  end

  # ===== AI提案API =====

  # AIアクションプラン提案を生成
  def suggest_action_plans
    video_id = params[:video_id].to_s.strip

    if video_id.blank?
      render json: { success: false, error: "動画IDが必要です" }, status: :unprocessable_entity
      return
    end

    # キャッシュ確認
    existing_post = Post.find_by(youtube_video_id: video_id)
    if existing_post&.suggested_action_plans.present?
      render json: { success: true, action_plans: existing_post.suggested_action_plans, cached: true }
      return
    end

    # 新規生成
    result = GeminiService.suggest_action_plans(
      video_id: video_id,
      title: params[:title].to_s.strip,
      description: nil
    )

    if result[:success]
      existing_post&.update(suggested_action_plans: result[:action_plans])
      render json: { success: true, action_plans: result[:action_plans] }
    else
      render json: { success: false, error: result[:error] }, status: :unprocessable_entity
    end
  end

  # アクションプランをYouTubeタイトル風に変換
  def convert_to_youtube_title
    action_plan = params[:action_plan].to_s.strip

    if action_plan.blank?
      render json: { success: false, error: "アクションプランが必要です" }, status: :unprocessable_entity
      return
    end

    result = GeminiService.convert_to_youtube_title(action_plan)

    if result[:success]
      render json: { success: true, title: result[:title] }
    else
      render json: { success: false, error: result[:error] }, status: :unprocessable_entity
    end
  end

  private

  # ===== Before Action =====

  def set_post
    @post = Post.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to posts_path, alert: t("posts.not_found")
  end

  def check_has_entries
    return if @post.has_entries_by?(current_user)

    redirect_to @post, alert: "この動画にはあなたのエントリーがありません"
  end

  def post_params
    params.require(:post).permit(:youtube_url)
  end

  # ===== Index ヘルパー =====

  # ランディングページを表示（未ログイン時）
  def render_landing_page
    # 本番環境ではログインページにリダイレクト
    if Rails.env.production?
      redirect_to new_user_session_path
      return
    end

    @ranking_posts = Post.by_action_count(limit: 5)
    @achieved_entries = load_achieved_entries_for_landing
    render "pages/landing", layout: "landing"
  end

  # ランディングページ用の達成エントリーを取得
  def load_achieved_entries_for_landing
    entries = PostEntry.achieved
                       .includes(:user, :post)
                       .where.not(thumbnail_url: [ nil, "" ])
                       .order(achieved_at: :desc)
                       .limit(6)

    # 6件に満たない場合は追加取得
    if entries.count < 6
      remaining = 6 - entries.count
      additional = PostEntry.achieved
                            .includes(:user, :post)
                            .where(thumbnail_url: [ nil, "" ])
                            .order(achieved_at: :desc)
                            .limit(remaining)
      entries = entries.to_a + additional.to_a
    end

    entries
  end

  # ユーザーでフィルターした投稿を取得
  def load_user_filtered_posts(base_scope)
    @filter_user = User.find_by(id: params[:user_id])
    return unless @filter_user

    post_ids = PostEntry.where(user_id: params[:user_id]).select(:post_id).distinct
    @posts = base_scope.where(id: post_ids).recent.page(params[:page]).per(20)
  end

  # チャンネルでフィルターした投稿を取得
  def load_channel_filtered_posts(base_scope)
    @filter_channel = params[:channel]
    @posts = base_scope.where(youtube_channel_name: @filter_channel)
                       .recent.page(params[:page]).per(20)
  end

  # セクション表示用データを取得
  def load_section_data
    posts_with_entries_ids = Post.with_entries.pluck(:id)
    @featured_post = Post.find(posts_with_entries_ids.sample) if posts_with_entries_ids.present?

    @popular_channels = Post.popular_channels(limit: 10)
    @ranking_posts = Post.by_action_count(limit: 10)
    @user_ranking = User.by_achieved_count(limit: 10)
    @recent_posts = Post.with_entries.recent.includes(:post_entries).limit(20)
  end

  # Turbo Stream用のレスポンス
  def render_posts_page
    if @posts.present?
      render partial: "posts/posts_page", locals: { posts: @posts }
    else
      head :ok
    end
  end

  # ===== Create With Action ヘルパー =====

  # create_with_actionのパラメータバリデーション
  def validate_create_with_action_params
    return { message: "動画URLが必要です", status: :unprocessable_entity } if params[:youtube_url].blank?
    return { message: "アクションプランが必要です", status: :unprocessable_entity } if params[:action_plan].blank?
    return { message: "ログインが必要です", status: :unauthorized } unless user_signed_in?

    existing = PostEntry.not_achieved.where(user: current_user).first
    if existing.present?
      return { message: "未達成のアクションプランがあります。達成してから新しいプランを投稿してください。", status: :unprocessable_entity }
    end

    nil
  end

  # PostEntryを構築
  def build_post_entry(post)
    post.post_entries.new(
      user: current_user,
      content: params[:action_plan],
      deadline: 7.days.from_now.to_date,
      thumbnail_url: params[:thumbnail_s3_key]
    )
  end

  # ===== 検索ヘルパー =====

  # オートコンプリート用の候補を取得
  def search_suggestions(query)
    Post
      .where("youtube_title ILIKE :q OR youtube_channel_name ILIKE :q", q: "%#{query}%")
      .limit(10)
      .pluck(:youtube_title, :youtube_channel_name)
      .flatten
      .compact
      .uniq
      .select { |s| s.downcase.include?(query.downcase) }
      .first(10)
  end

  # 既存投稿を検索してJSON形式で返す
  def search_existing_posts(query)
    posts = Post.joins(:post_entries)
                .where("youtube_title ILIKE :q OR youtube_channel_name ILIKE :q", q: "%#{query}%")
                .distinct
                .order(created_at: :desc)
                .limit(10)

    posts.map do |post|
      {
        id: post.id,
        title: post.youtube_title,
        channel_name: post.youtube_channel_name,
        thumbnail_url: post.youtube_thumbnail_url(size: :mqdefault),
        url: post_path(post),
        entry_count: post.post_entries.count
      }
    end
  end
end
