# app/controllers/posts_controller.rb
class PostsController < ApplicationController
  before_action :authenticate_user!, except: [ :index, :show, :autocomplete, :youtube_search, :find_or_create, :youtube_comments, :discover_comments, :trending, :channels, :recent ]
  before_action :set_post, only: [ :show, :edit, :update, :destroy, :summarize, :youtube_comments, :discover_comments, :suggest_action_plans ]
  before_action :check_has_entries, only: [ :edit, :update, :destroy ]

  def index
    @q = Post.ransack(params[:q])
    base_scope = @q.result(distinct: true).includes(:achievements, :cheers, :post_entries)

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
      @popular_channels = Post.popular_channels(limit: 20)
      @ranking_posts = Post.by_action_count(limit: 30)

      # ユーザー達成数ランキング（期間フィルター対応）
      @user_ranking_period = (params[:user_ranking_period] || :all).to_sym
      @user_ranking = User.by_achieved_count(limit: 5, period: @user_ranking_period)

      # 最近の投稿（ランキングと重複してもOK）
      @recent_posts = Post.recent.includes(:post_entries).limit(20)
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

  # 急上昇一覧ページ
  def trending
    @posts = Post.trending(limit: nil).page(params[:page]).per(20)
  end

  # チャンネル一覧ページ
  def channels
    @channels = Post.popular_channels(limit: 100)
  end


  # 最近の投稿一覧ページ
  def recent
    @posts = Post.recent.page(params[:page]).per(20)
  end

  def show
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
      # 新規作成時はAI要約を自動生成（ジョブキュー未設定でもエラーにしない）
      if is_new_post && @post.ai_summary.blank?
        begin
          GenerateSummaryJob.perform_later(@post.id)
        rescue StandardError => e
          Rails.logger.warn("Failed to enqueue GenerateSummaryJob: #{e.message}")
        end
      end
      render json: { success: true, post_id: @post.id, url: post_path(@post) }
    else
      render json: { success: false, error: "動画の情報を取得できませんでした" }, status: :unprocessable_entity
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

  # AI学習ガイドを生成
  def summarize
    result = GeminiService.summarize_video(@post)

    respond_to do |format|
      if result[:success]
        @summary = result[:summary]
        # 要約をDBに保存
        @post.update(ai_summary: @summary)
        format.turbo_stream
        format.json { render json: { success: true, summary: @summary } }
      else
        @error = result[:error]
        format.turbo_stream { render :summarize_error }
        format.json { render json: { success: false, error: @error }, status: :unprocessable_entity }
      end
    end
  end

  # YouTubeコメントを取得
  def youtube_comments
    @comments = YoutubeService.fetch_top_comments(@post.youtube_video_id, max_results: 20)

    respond_to do |format|
      format.json { render json: { success: true, comments: @comments } }
      format.turbo_stream
      format.html { render layout: false }
    end
  end

  # AIアクションプラン提案を生成
  def suggest_action_plans
    # 既にDB保存済みの提案があれば返す
    if @post.suggested_action_plans.present?
      respond_to do |format|
        format.json { render json: { success: true, action_plans: @post.suggested_action_plans, cached: true } }
      end
      return
    end

    # 新規生成
    result = GeminiService.suggest_action_plans(
      video_id: @post.youtube_video_id,
      title: @post.youtube_title,
      description: nil
    )

    respond_to do |format|
      if result[:success]
        # DBに保存
        @post.update(suggested_action_plans: result[:action_plans])
        format.json { render json: { success: true, action_plans: result[:action_plans] } }
        format.turbo_stream do
          @action_plans = result[:action_plans]
        end
      else
        format.json { render json: { success: false, error: result[:error] }, status: :unprocessable_entity }
        format.turbo_stream do
          @error = result[:error]
          render :suggest_action_plans_error
        end
      end
    end
  end

  # YouTubeコメントを取得・保存（ブックマーク用）
  def discover_comments
    # 既に保存済みコメントがある場合はそれを返す
    existing_comments = @post.youtube_comments.by_like_count
    if existing_comments.any?
      @youtube_comments = existing_comments
      respond_to do |format|
        format.json { render json: { success: true, comments: format_youtube_comments(@youtube_comments), cached: true } }
        format.turbo_stream
        format.html { render layout: false }
      end
      return
    end

    # YouTubeからコメントを取得
    raw_comments = YoutubeService.fetch_top_comments(@post.youtube_video_id, max_results: 50)

    if raw_comments.blank?
      respond_to do |format|
        format.json { render json: { success: false, error: "コメントを取得できませんでした" }, status: :unprocessable_entity }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("youtube-comments-container", partial: "posts/no_comments") }
      end
      return
    end

    # コメントを保存
    save_comments(raw_comments)
    @youtube_comments = @post.youtube_comments.reload.by_like_count

    respond_to do |format|
      format.json { render json: { success: true, comments: format_youtube_comments(@youtube_comments) } }
      format.turbo_stream
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

  # YouTubeコメントを保存
  def save_comments(comments)
    comments.each do |comment|
      @post.youtube_comments.find_or_create_by(youtube_comment_id: comment[:comment_id]) do |yc|
        yc.author_name = comment[:author]
        yc.author_image_url = comment[:author_image]
        yc.author_channel_url = comment[:author_channel_url]
        yc.content = comment[:text]
        yc.like_count = comment[:like_count] || 0
        yc.youtube_published_at = comment[:published_at]
      end
    end
  end

  # YoutubeCommentをJSON形式にフォーマット
  def format_youtube_comments(comments)
    comments.map do |comment|
      {
        id: comment.id,
        comment_id: comment.youtube_comment_id,
        author: comment.author_name,
        author_image: comment.author_image_url,
        author_channel_url: comment.author_channel_url,
        text: comment.content,
        like_count: comment.like_count,
        youtube_url: comment.youtube_url,
        bookmarked: user_signed_in? ? comment.bookmarked_by?(current_user) : false
      }
    end
  end
end
