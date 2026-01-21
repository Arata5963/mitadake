# app/controllers/posts_controller.rb
class PostsController < ApplicationController
  before_action :authenticate_user!, except: [ :index, :show, :autocomplete, :youtube_search, :find_or_create, :recent, :convert_to_youtube_title, :suggest_action_plans ]
  before_action :set_post, only: [ :show, :edit, :update, :destroy ]
  before_action :check_has_entries, only: [ :edit, :update, :destroy ]

  def index
    # 未ログインユーザーの処理
    unless user_signed_in?
      # 本番環境ではログインページにリダイレクト（ランディングページ未完成のため）
      if Rails.env.production?
        redirect_to new_user_session_path
        return
      end

      # 開発環境ではランディングページを表示
      @ranking_posts = Post.by_action_count(limit: 5)
      @achieved_entries = PostEntry.achieved
                                   .includes(:user, :post)
                                   .where.not(thumbnail_url: [nil, ""])
                                   .order(achieved_at: :desc)
                                   .limit(6)
      if @achieved_entries.count < 6
        remaining = 6 - @achieved_entries.count
        additional = PostEntry.achieved
                              .includes(:user, :post)
                              .where(thumbnail_url: [nil, ""])
                              .order(achieved_at: :desc)
                              .limit(remaining)
        @achieved_entries = @achieved_entries.to_a + additional.to_a
      end
      render "pages/landing", layout: "landing"
      return
    end

    @q = Post.ransack(params[:q])
    base_scope = @q.result(distinct: true).includes(:achievements, :post_entries)

    # ===== ユーザー絞り込み =====
    if params[:user_id].present?
      @filter_user = User.find_by(id: params[:user_id])
      if @filter_user
        # そのユーザーがエントリーを持つ投稿のみ表示
        post_ids_with_entries = PostEntry.where(user_id: params[:user_id]).select(:post_id).distinct
        base_scope = base_scope.where(id: post_ids_with_entries)
        # ユーザーフィルター時は従来のグリッド表示
        @posts = base_scope.recent.page(params[:page]).per(20)
      end

    # ===== チャンネル絞り込み =====
    elsif params[:channel].present?
      @filter_channel = params[:channel]
      base_scope = base_scope.where(youtube_channel_name: @filter_channel)
      @posts = base_scope.recent.page(params[:page]).per(20)

    else
      # ===== セクション表示用データ =====
      # フィーチャー動画（全投稿から完全ランダム）
      posts_with_entries_ids = Post.with_entries.pluck(:id)
      @featured_post = Post.find(posts_with_entries_ids.sample) if posts_with_entries_ids.present?

      @popular_channels = Post.popular_channels(limit: 10)
      @ranking_posts = Post.by_action_count(limit: 10)

      # ユーザーアクション数ランキング（全期間）
      @user_ranking = User.by_achieved_count(limit: 10)

      # 最近の投稿（アクションプランがある投稿のみ）
      @recent_posts = Post.with_entries.recent.includes(:post_entries).limit(20)
    end

    respond_to do |format|
      format.html
      format.turbo_stream do
        if @posts.present?
          render partial: "posts/posts_page", locals: { posts: @posts }
        else
          head :ok
        end
      end
    end
  end

  # 最近の投稿一覧ページ
  def recent
    @posts = Post.with_entries.recent.page(params[:page]).per(20)
  end

  def show
  end

  # 新規投稿ページ
  def new
    # before_action :authenticate_user! で認証済み
  end

  # YouTube URLから投稿を検索または作成してリダイレクト
  def find_or_create
    youtube_url = params[:youtube_url]

    if youtube_url.blank?
      render json: { success: false, error: "URLが必要です" }, status: :unprocessable_entity
      return
    end

    is_new_post = !Post.exists?(youtube_video_id: Post.extract_video_id(youtube_url))
    @post = Post.find_or_create_by_video(youtube_url: youtube_url)

    if @post
      render json: { success: true, post_id: @post.id, url: post_path(@post) }
    else
      render json: { success: false, error: "動画の情報を取得できませんでした" }, status: :unprocessable_entity
    end
  end

  # 動画とアクションプランを同時に作成
  def create_with_action
    youtube_url = params[:youtube_url]
    action_plan = params[:action_plan]

    # バリデーション
    if youtube_url.blank?
      render json: { success: false, error: "動画URLが必要です" }, status: :unprocessable_entity
      return
    end

    if action_plan.blank?
      render json: { success: false, error: "アクションプランが必要です" }, status: :unprocessable_entity
      return
    end

    unless user_signed_in?
      render json: { success: false, error: "ログインが必要です" }, status: :unauthorized
      return
    end

    # 未達成のアクションプランがあるかチェック
    existing_incomplete = PostEntry.not_achieved.where(user: current_user).first
    if existing_incomplete.present?
      render json: { success: false, error: "未達成のアクションプランがあります。達成してから新しいプランを投稿してください。" }, status: :unprocessable_entity
      return
    end

    # 動画を検索または作成
    is_new_post = !Post.exists?(youtube_video_id: Post.extract_video_id(youtube_url))
    @post = Post.find_or_create_by_video(youtube_url: youtube_url)

    unless @post
      render json: { success: false, error: "動画の情報を取得できませんでした" }, status: :unprocessable_entity
      return
    end

    # サムネイル処理（署名付きURL方式：クライアントから直接S3にアップロード済み）
    thumbnail_s3_key = params[:thumbnail_s3_key]

    # アクションプランを作成（期限は7日後）
    @entry = @post.post_entries.new(
      user: current_user,
      content: action_plan,
      deadline: 7.days.from_now.to_date,
      thumbnail_url: thumbnail_s3_key
    )

    if @entry.save
      render json: { success: true, post_id: @post.id, entry_id: @entry.id, url: post_path(@post) }
    else
      render json: { success: false, error: @entry.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end
  end

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
    # 自分のエントリーのみ削除
    @post.entries_by_user(current_user).destroy_all

    # 他にエントリーがなければ投稿自体も削除
    if @post.post_entries.empty?
      @post.destroy
    end

    redirect_to posts_path, notice: "エントリーを削除しました"
  end

  def autocomplete
    query = params[:q].to_s.strip

    if query.length >= 2
      @suggestions = Post
        .where(
          "youtube_title ILIKE :q OR youtube_channel_name ILIKE :q",
          q: "%#{query}%"
        )
        .limit(10)
        .pluck(:youtube_title, :youtube_channel_name)
        .flatten
        .compact
        .uniq
        .select { |s| s.downcase.include?(query.downcase) }
        .first(10)
    else
      @suggestions = []
    end

    render layout: false
  end

  # YouTube動画を検索
  def youtube_search
    query = params[:q].to_s.strip

    if query.length >= 2
      @videos = YoutubeService.search_videos(query, max_results: 8)
    else
      @videos = []
    end

    respond_to do |format|
      format.json { render json: @videos }
      format.html { render layout: false }
    end
  end

  # 既存の投稿を検索（アクションプランがあるもののみ）
  def search_posts
    query = params[:q].to_s.strip

    if query.length >= 2
      # アクションプランが1つ以上ある投稿のみ検索
      @posts = Post.joins(:post_entries)
                   .where("youtube_title ILIKE :q OR youtube_channel_name ILIKE :q", q: "%#{query}%")
                   .distinct
                   .order(created_at: :desc)
                   .limit(10)

      results = @posts.map do |post|
        {
          id: post.id,
          title: post.youtube_title,
          channel_name: post.youtube_channel_name,
          thumbnail_url: post.youtube_thumbnail_url(size: :mqdefault),
          url: post_path(post),
          entry_count: post.post_entries.count
        }
      end
    else
      results = []
    end

    render json: results
  end

  # AIアクションプラン提案を生成（Post作成不要）
  def suggest_action_plans
    video_id = params[:video_id].to_s.strip
    title = params[:title].to_s.strip

    if video_id.blank?
      render json: { success: false, error: "動画IDが必要です" }, status: :unprocessable_entity
      return
    end

    # 既存のPostがあれば、キャッシュされた提案を返す
    existing_post = Post.find_by(youtube_video_id: video_id)
    if existing_post&.suggested_action_plans.present?
      respond_to do |format|
        format.json { render json: { success: true, action_plans: existing_post.suggested_action_plans, cached: true } }
      end
      return
    end

    # 新規生成
    result = GeminiService.suggest_action_plans(
      video_id: video_id,
      title: title,
      description: nil
    )

    respond_to do |format|
      if result[:success]
        # 既存Postがあれば提案をキャッシュ保存（なければ保存しない）
        existing_post&.update(suggested_action_plans: result[:action_plans])
        format.json { render json: { success: true, action_plans: result[:action_plans] } }
      else
        format.json { render json: { success: false, error: result[:error] }, status: :unprocessable_entity }
      end
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

  def set_post
    @post = Post.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to posts_path, alert: t("posts.not_found")
  end

  def check_has_entries
    unless @post.has_entries_by?(current_user)
      redirect_to @post, alert: "この動画にはあなたのエントリーがありません"
    end
  end

  def post_params
    params.require(:post).permit(:youtube_url)
  end
end
