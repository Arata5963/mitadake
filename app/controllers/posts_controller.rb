# app/controllers/posts_controller.rb
# ==========================================
# 投稿（YouTube動画）コントローラー
# ==========================================
#
# 【このクラスの役割】
# YouTube動画の登録・表示・検索を担当する。
# このアプリの中心的なコントローラー。
#
# 【主な機能】
# 1. 動画一覧・検索・フィルター表示
# 2. 動画とアクションプランの同時作成
# 3. YouTube動画検索API
# 4. AIによるアクションプラン提案
#
# 【ルーティング概要】
# - GET /posts → index（一覧）
# - GET /posts/:id → show（詳細）
# - GET /posts/new → new（新規作成フォーム）
# - POST /posts/find_or_create → find_or_create（URLから動画検索/作成）
# - POST /posts/create_with_action → create_with_action（動画+プラン同時作成）
# - GET /posts/youtube_search → youtube_search（YouTube検索API）
# - GET /posts/suggest_action_plans → suggest_action_plans（AI提案）
#
class PostsController < ApplicationController
  # ==========================================
  # before_action（各アクションの前に実行）
  # ==========================================
  #
  # 【authenticate_user! とは？】
  # Deviseが提供するメソッド。ログイン必須にする。
  # 未ログインの場合、ログインページにリダイレクトされる。
  #
  # 【except: [...] とは？】
  # 指定したアクションでは認証を「しない」。
  # つまり、ここに書いたアクションは未ログインでもアクセス可能。
  #
  before_action :authenticate_user!, except: [
    :index, :show, :autocomplete, :youtube_search,
    :find_or_create, :recent, :convert_to_youtube_title, :suggest_action_plans
  ]

  # 特定のアクションの前に動画を取得
  before_action :set_post, only: [ :show, :edit, :update, :update_with_action, :destroy ]

  # 編集・更新・削除は、自分のエントリーがある場合のみ許可
  before_action :check_has_entries, only: [ :edit, :update, :update_with_action, :destroy ]

  # ==========================================
  # 一覧・詳細アクション
  # ==========================================

  # ------------------------------------------
  # 投稿一覧（トップページ）
  # ------------------------------------------
  # 【ルート】GET /posts（または GET /）
  #
  # 【処理の分岐】
  # - 未ログイン: ランディングページ表示
  # - ログイン済み + フィルターあり: フィルター結果表示
  # - ログイン済み + フィルターなし: セクション別表示
  #
  # 【respond_to とは？】
  # リクエストの形式（HTML/JSON/Turbo Stream）によって
  # 異なるレスポンスを返す仕組み。
  #
  def index
    # 未ログインの場合はランディングページを表示
    unless user_signed_in?
      render_landing_page
      return
    end

    # 【Ransack とは？】
    # 検索機能を簡単に実装できるgem。
    # params[:q] に検索条件が入っている。
    @q = Post.ransack(params[:q])
    base_scope = @q.result(distinct: true).includes(:post_entries)

    # フィルター条件に応じてデータを取得
    if params[:user_id].present?
      # ユーザーでフィルター（特定ユーザーの動画一覧）
      load_user_filtered_posts(base_scope)
    elsif params[:channel].present?
      # チャンネルでフィルター（特定チャンネルの動画一覧）
      load_channel_filtered_posts(base_scope)
    else
      # フィルターなし: セクション別表示
      load_section_data
    end

    # レスポンス形式に応じた処理
    respond_to do |format|
      format.html
      format.turbo_stream { render_posts_page }
    end
  end

  # ------------------------------------------
  # 最近の投稿一覧
  # ------------------------------------------
  # 【ルート】GET /posts/recent
  #
  def recent
    # 【page と per とは？】
    # Kaminari（ページネーションgem）のメソッド。
    # page(params[:page]) で現在のページを指定
    # per(20) で1ページあたりの件数を指定
    @posts = Post.with_achieved_entries.recent.page(params[:page]).per(20)
  end

  # ------------------------------------------
  # 動画詳細
  # ------------------------------------------
  # 【ルート】GET /posts/:id
  #
  # @post は set_post で取得済み
  #
  def show
    # ビュー: app/views/posts/show.html.erb
  end

  # ==========================================
  # 投稿作成アクション
  # ==========================================

  # ------------------------------------------
  # 新規投稿ページ
  # ------------------------------------------
  # 【ルート】GET /posts/new
  #
  def new
    # 認証は before_action で実施済み
    # ビュー: app/views/posts/new.html.erb
  end

  # ------------------------------------------
  # YouTube URLから投稿を検索または作成
  # ------------------------------------------
  # 【ルート】POST /posts/find_or_create
  #
  # 【何をするアクション？】
  # YouTube URLを受け取り、その動画がDBにあれば返し、
  # なければ新規作成して返す。
  #
  # 【レスポンス（JSON）】
  # 成功: { success: true, post_id: 123, url: "/posts/123" }
  # 失敗: { success: false, error: "エラーメッセージ" }
  #
  def find_or_create
    youtube_url = params[:youtube_url]

    if youtube_url.blank?
      render json: { success: false, error: "URLが必要です" }, status: :unprocessable_entity
      return
    end

    # Post.find_or_create_by_video で検索または作成
    # 詳細は app/models/post.rb を参照
    @post = Post.find_or_create_by_video(youtube_url: youtube_url)

    if @post
      render json: { success: true, post_id: @post.id, url: post_path(@post) }
    else
      render json: { success: false, error: "動画の情報を取得できませんでした" }, status: :unprocessable_entity
    end
  end

  # ------------------------------------------
  # 動画とアクションプランを同時に作成
  # ------------------------------------------
  # 【ルート】POST /posts/create_with_action
  #
  # 【何をするアクション？】
  # 1. YouTube動画を検索または作成
  # 2. その動画にアクションプランを紐づけて作成
  #
  # 【リクエストパラメータ】
  # - youtube_url: YouTube動画のURL
  # - action_plan: アクションプランの内容
  # - thumbnail_s3_key: カスタムサムネイルのS3キー（省略可）
  #
  def create_with_action
    # バリデーション（URL・アクションプランの存在確認等）
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
      render json: { success: true, post_id: @post.id, entry_id: @entry.id, url: mypage_path }
    else
      render json: { success: false, error: @entry.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end
  end

  # ==========================================
  # 投稿編集・削除アクション
  # ==========================================

  def edit
    # @post は set_post で取得済み
  end

  def update
    if @post.update(post_params)
      redirect_to @post, notice: t("posts.update.success")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # ------------------------------------------
  # 動画+アクションプラン同時更新（Ajax）
  # ------------------------------------------
  # 【ルート】PATCH /posts/:id/update_with_action
  #
  # 【何をするアクション？】
  # 編集画面から動画とアクションプランを同時に更新する。
  # 動画を変更した場合は新しいPostに移動する。
  #
  def update_with_action
    # 現在のユーザーのエントリーを取得
    @entry = @post.entries_by_user(current_user).first

    unless @entry
      render json: { success: false, error: "アクションプランが見つかりません" }, status: :not_found
      return
    end

    # アクションプランの内容を更新
    action_plan = params[:action_plan].to_s.strip
    if action_plan.blank?
      render json: { success: false, error: "アクションプランを入力してください" }, status: :unprocessable_entity
      return
    end

    # 動画が変更されたかチェック
    new_youtube_url = params[:youtube_url].to_s.strip
    if new_youtube_url.present?
      new_video_id = Post.extract_video_id(new_youtube_url)
      current_video_id = @post.youtube_video_id

      if new_video_id && new_video_id != current_video_id
        # 新しい動画に変更
        new_post = Post.find_or_create_by_video(youtube_url: new_youtube_url)
        unless new_post
          render json: { success: false, error: "動画の情報を取得できませんでした" }, status: :unprocessable_entity
          return
        end
        @entry.post = new_post
        @post = new_post
      end
    end

    # アクションプラン内容を更新
    @entry.content = action_plan

    # サムネイル画像の処理（S3キーで更新）
    if params[:thumbnail_s3_key].present?
      @entry.thumbnail_url = params[:thumbnail_s3_key]
    end

    if @entry.save
      render json: { success: true, post_id: @post.id, entry_id: @entry.id, url: post_path(@post) }
    else
      render json: { success: false, error: @entry.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end
  end

  # ------------------------------------------
  # 削除
  # ------------------------------------------
  # 【処理内容】
  # 自分のアクションプランのみ削除する。
  # 他にアクションプランがなければ動画自体も削除。
  #
  def destroy
    # 自分のエントリーのみ削除
    @post.entries_by_user(current_user).destroy_all

    # 他にエントリーがなければ投稿自体も削除
    @post.destroy if @post.post_entries.empty?

    redirect_to posts_path, notice: "エントリーを削除しました"
  end

  # ==========================================
  # 検索API
  # ==========================================

  # ------------------------------------------
  # 投稿タイトル・チャンネル名のオートコンプリート
  # ------------------------------------------
  # 【ルート】GET /posts/autocomplete
  #
  # 【何をするアクション？】
  # 検索フォームで入力中に候補を表示するためのAPI。
  # DBに登録済みの動画タイトル・チャンネル名から候補を返す。
  #
  def autocomplete
    query = params[:q].to_s.strip
    @suggestions = query.length >= 2 ? search_suggestions(query) : []
    render layout: false  # レイアウトなしでレンダリング
  end

  # ------------------------------------------
  # YouTube動画を検索
  # ------------------------------------------
  # 【ルート】GET /posts/youtube_search
  #
  # 【何をするアクション？】
  # YouTube Data APIを使って動画を検索する。
  # 新規動画登録時の動画選択に使用。
  #
  def youtube_search
    query = params[:q].to_s.strip
    @videos = query.length >= 2 ? YoutubeService.search_videos(query, max_results: 8) : []

    respond_to do |format|
      format.json { render json: @videos }
      format.html { render layout: false }
    end
  end

  # ------------------------------------------
  # 既存の投稿を検索
  # ------------------------------------------
  # 【ルート】GET /posts/search_posts
  #
  # 【何をするアクション？】
  # DBに登録済みの動画を検索する。
  # アクションプランがある動画のみを返す。
  #
  def search_posts
    query = params[:q].to_s.strip
    results = query.length >= 2 ? search_existing_posts(query) : []
    render json: results
  end

  # ==========================================
  # AI提案API
  # ==========================================

  # ------------------------------------------
  # AIアクションプラン提案を生成
  # ------------------------------------------
  # 【ルート】GET /posts/suggest_action_plans
  #
  # 【何をするアクション？】
  # GeminiServiceを使って、動画の内容から
  # アクションプランを3つ提案する。
  #
  # 【キャッシュ機能】
  # 同じ動画に対する提案は、DBに保存して再利用する。
  # API呼び出しを減らしてコスト削減。
  #
  def suggest_action_plans
    video_id = params[:video_id].to_s.strip

    if video_id.blank?
      render json: { success: false, error: "動画IDが必要です" }, status: :unprocessable_entity
      return
    end

    # キャッシュ確認: すでに提案が保存されているか
    existing_post = Post.find_by(youtube_video_id: video_id)
    if existing_post&.suggested_action_plans.present?
      render json: { success: true, action_plans: existing_post.suggested_action_plans, cached: true }
      return
    end

    # 新規生成: GeminiServiceを使ってAI生成
    result = GeminiService.suggest_action_plans(
      video_id: video_id,
      title: params[:title].to_s.strip,
      description: nil
    )

    if result[:success]
      # キャッシュとして保存
      existing_post&.update(suggested_action_plans: result[:action_plans])
      render json: { success: true, action_plans: result[:action_plans] }
    else
      render json: { success: false, error: result[:error] }, status: :unprocessable_entity
    end
  end

  # ------------------------------------------
  # アクションプランをYouTubeタイトル風に変換
  # ------------------------------------------
  # 【ルート】POST /posts/convert_to_youtube_title
  #
  # 【何をするアクション？】
  # ユーザーが入力したアクションプランを、
  # 「やってみた」系のキャッチーなタイトルに変換する。
  #
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

  # ==========================================
  # Before Action メソッド
  # ==========================================

  # 動画を取得
  def set_post
    @post = Post.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to posts_path, alert: t("posts.not_found")
  end

  # 自分のエントリーがあるかチェック
  def check_has_entries
    return if @post.has_entries_by?(current_user)

    redirect_to @post, alert: "この動画にはあなたのエントリーがありません"
  end

  # Strong Parameters
  def post_params
    params.require(:post).permit(:youtube_url)
  end

  # ==========================================
  # Index ヘルパーメソッド
  # ==========================================

  # ------------------------------------------
  # ランディングページを表示（未ログイン時）
  # ------------------------------------------
  def render_landing_page
    # 本番環境ではログインページにリダイレクト
    if Rails.env.production?
      redirect_to new_user_session_path
      return
    end

    # ランディングページ用のデータを取得
    @ranking_posts = Post.by_action_count(limit: 5)
    @achieved_entries = load_achieved_entries_for_landing
    render "pages/landing", layout: "landing"
  end

  # ランディングページ用の達成エントリーを取得
  def load_achieved_entries_for_landing
    # サムネイル画像がある達成エントリーを優先取得
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
    posts_with_achieved_ids = Post.with_achieved_entries.pluck(:id)
    @featured_post = Post.find(posts_with_achieved_ids.sample) if posts_with_achieved_ids.present?

    @popular_channels = Post.popular_channels(limit: 10)
    @ranking_posts = Post.by_action_count(limit: 10)
    @user_ranking = User.by_achieved_count(limit: 10)
    @recent_posts = Post.with_achieved_entries.recent.includes(:post_entries).limit(20)
  end

  # Turbo Stream用のレスポンス
  def render_posts_page
    if @posts.present?
      render partial: "posts/posts_page", locals: { posts: @posts }
    else
      head :ok
    end
  end

  # ==========================================
  # Create With Action ヘルパーメソッド
  # ==========================================

  # create_with_actionのパラメータバリデーション
  def validate_create_with_action_params
    return { message: "動画URLが必要です", status: :unprocessable_entity } if params[:youtube_url].blank?
    return { message: "アクションプランが必要です", status: :unprocessable_entity } if params[:action_plan].blank?
    return { message: "ログインが必要です", status: :unauthorized } unless user_signed_in?

    # 複数アクションプラン対応により、未達成チェックは不要

    nil  # エラーなし
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

  # ==========================================
  # 検索ヘルパーメソッド
  # ==========================================

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
