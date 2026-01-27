# 投稿（YouTube動画）コントローラー
# YouTube動画の登録・表示・検索を担当

class PostsController < ApplicationController
  before_action :authenticate_user!, except: [                                       # ログイン不要なアクション
    :index, :show, :autocomplete, :youtube_search,                                   # 一覧・詳細・検索系
    :find_or_create, :recent, :convert_to_youtube_title, :suggest_action_plans       # 動画作成・AI提案系
  ]
  before_action :set_post, only: [ :show, :edit, :update, :update_with_action, :destroy ]  # 動画取得が必要なアクション
  before_action :check_has_entries, only: [ :edit, :update, :update_with_action, :destroy ]  # 自分のエントリーがあるかチェック

  # 投稿一覧（トップページ）
  def index
    unless user_signed_in?                                                           # 未ログインの場合
      redirect_to root_path                                                          # ルートへリダイレクト（LP表示）
      return                                                                         # 処理終了
    end

    @q = Post.ransack(params[:q])                                                    # Ransack検索オブジェクト作成
    base_scope = @q.result(distinct: true).includes(:post_entries)                   # 検索結果取得

    if params[:user_id].present?                                                     # ユーザーでフィルター
      load_user_filtered_posts(base_scope)                                           # ユーザーの投稿を取得
    elsif params[:channel].present?                                                  # チャンネルでフィルター
      load_channel_filtered_posts(base_scope)                                        # チャンネルの投稿を取得
    else                                                                             # フィルターなし
      load_section_data                                                              # セクション別表示データを取得
    end

    respond_to do |format|                                                           # レスポンス形式に応じた処理
      format.html                                                                    # HTML形式
      format.turbo_stream { render_posts_page }                                      # Turbo Stream形式
    end
  end

  # 最近の投稿一覧
  def recent
    @posts = Post.with_achieved_entries.recent.page(params[:page]).per(20)           # 達成済みエントリーありの投稿を取得
  end

  # 動画詳細
  def show
    # @post は set_post で取得済み
  end

  # 新規投稿ページ
  def new
    # ビュー: app/views/posts/new.html.erb
  end

  # YouTube URLから投稿を検索または作成
  def find_or_create
    youtube_url = params[:youtube_url]                                               # URLを取得

    if youtube_url.blank?                                                            # URLが空の場合
      render json: { success: false, error: "URLが必要です" }, status: :unprocessable_entity  # エラーを返す
      return                                                                         # 処理終了
    end

    @post = Post.find_or_create_by_video(youtube_url: youtube_url)                   # 動画を検索または作成

    if @post                                                                         # 成功した場合
      render json: { success: true, post_id: @post.id, url: post_path(@post) }       # 成功レスポンス
    else                                                                             # 失敗した場合
      render json: { success: false, error: "動画の情報を取得できませんでした" }, status: :unprocessable_entity  # エラーレスポンス
    end
  end

  # 動画とアクションプランを同時に作成
  def create_with_action
    error = validate_create_with_action_params                                       # パラメータバリデーション
    if error                                                                         # エラーがある場合
      render json: { success: false, error: error[:message] }, status: error[:status]  # エラーを返す
      return                                                                         # 処理終了
    end

    @post = Post.find_or_create_by_video(youtube_url: params[:youtube_url])          # 動画を検索または作成
    unless @post                                                                     # 失敗した場合
      render json: { success: false, error: "動画の情報を取得できませんでした" }, status: :unprocessable_entity  # エラーを返す
      return                                                                         # 処理終了
    end

    @entry = build_post_entry(@post)                                                 # アクションプランを構築

    if @entry.save                                                                   # 保存成功
      render json: { success: true, post_id: @post.id, entry_id: @entry.id, url: mypage_path }  # 成功レスポンス
    else                                                                             # 保存失敗
      render json: { success: false, error: @entry.errors.full_messages.join(", ") }, status: :unprocessable_entity  # エラーレスポンス
    end
  end

  # 編集画面
  def edit
    # @post は set_post で取得済み
  end

  # 更新
  def update
    if @post.update(post_params)                                                     # 更新成功
      redirect_to @post, notice: t("posts.update.success")                           # 詳細ページへリダイレクト
    else                                                                             # 更新失敗
      render :edit, status: :unprocessable_entity                                    # 編集画面を再表示
    end
  end

  # 動画+アクションプラン同時更新（Ajax）
  def update_with_action
    @entry = @post.entries_by_user(current_user).first                               # 現在のユーザーのエントリーを取得

    unless @entry                                                                    # エントリーがない場合
      render json: { success: false, error: "アクションプランが見つかりません" }, status: :not_found  # エラーを返す
      return                                                                         # 処理終了
    end

    action_plan = params[:action_plan].to_s.strip                                    # アクションプランを取得
    if action_plan.blank?                                                            # 空の場合
      render json: { success: false, error: "アクションプランを入力してください" }, status: :unprocessable_entity  # エラーを返す
      return                                                                         # 処理終了
    end

    new_youtube_url = params[:youtube_url].to_s.strip                                # 新しいURLを取得
    if new_youtube_url.present?                                                      # URLが指定された場合
      new_video_id = Post.extract_video_id(new_youtube_url)                          # 新しい動画IDを抽出
      current_video_id = @post.youtube_video_id                                      # 現在の動画IDを取得

      if new_video_id && new_video_id != current_video_id                            # 動画が変更された場合
        new_post = Post.find_or_create_by_video(youtube_url: new_youtube_url)        # 新しい動画を取得
        unless new_post                                                              # 失敗した場合
          render json: { success: false, error: "動画の情報を取得できませんでした" }, status: :unprocessable_entity  # エラーを返す
          return                                                                     # 処理終了
        end
        @entry.post = new_post                                                       # エントリーを新しい動画に紐づけ
        @post = new_post                                                             # @postを更新
      end
    end

    @entry.content = action_plan                                                     # アクションプラン内容を更新

    if params[:thumbnail_s3_key].present?                                            # サムネイルが指定された場合
      @entry.thumbnail_url = params[:thumbnail_s3_key]                               # サムネイルを更新
    end

    if @entry.save                                                                   # 保存成功
      render json: { success: true, post_id: @post.id, entry_id: @entry.id, url: post_path(@post) }  # 成功レスポンス
    else                                                                             # 保存失敗
      render json: { success: false, error: @entry.errors.full_messages.join(", ") }, status: :unprocessable_entity  # エラーレスポンス
    end
  end

  # 削除
  def destroy
    @post.entries_by_user(current_user).destroy_all                                  # 自分のエントリーのみ削除
    @post.destroy if @post.post_entries.empty?                                       # 他にエントリーがなければ投稿も削除
    redirect_to posts_path, notice: "エントリーを削除しました"                        # 一覧へリダイレクト
  end

  # 投稿タイトル・チャンネル名のオートコンプリート
  def autocomplete
    query = params[:q].to_s.strip                                                    # クエリを取得
    @suggestions = query.length >= 2 ? search_suggestions(query) : []                # 2文字以上なら候補を取得
    render layout: false                                                             # レイアウトなしでレンダリング
  end

  # YouTube動画を検索
  def youtube_search
    query = params[:q].to_s.strip                                                    # クエリを取得
    @videos = query.length >= 2 ? YoutubeService.search_videos(query, max_results: 8) : []  # 2文字以上なら検索

    respond_to do |format|                                                           # レスポンス形式に応じた処理
      format.json { render json: @videos }                                           # JSON形式
      format.html { render layout: false }                                           # HTML形式（レイアウトなし）
    end
  end

  # 既存の投稿を検索
  def search_posts
    query = params[:q].to_s.strip                                                    # クエリを取得
    results = query.length >= 2 ? search_existing_posts(query) : []                  # 2文字以上なら検索
    render json: results                                                             # JSONで返す
  end

  # AIアクションプラン提案を生成
  def suggest_action_plans
    video_id = params[:video_id].to_s.strip                                          # 動画IDを取得

    if video_id.blank?                                                               # 動画IDが空の場合
      render json: { success: false, error: "動画IDが必要です" }, status: :unprocessable_entity  # エラーを返す
      return                                                                         # 処理終了
    end

    existing_post = Post.find_by(youtube_video_id: video_id)                         # 既存のPostを検索
    if existing_post&.suggested_action_plans.present?                                # キャッシュがある場合
      render json: { success: true, action_plans: existing_post.suggested_action_plans, cached: true }  # キャッシュを返す
      return                                                                         # 処理終了
    end

    result = GeminiService.suggest_action_plans(                                     # GeminiServiceでAI生成
      video_id: video_id,                                                            # 動画ID
      title: params[:title].to_s.strip,                                              # タイトル
      description: nil                                                               # 説明（省略）
    )

    if result[:success]                                                              # 成功した場合
      existing_post&.update(suggested_action_plans: result[:action_plans])           # キャッシュとして保存
      render json: { success: true, action_plans: result[:action_plans] }            # 成功レスポンス
    else                                                                             # 失敗した場合
      render json: { success: false, error: result[:error] }, status: :unprocessable_entity  # エラーレスポンス
    end
  end

  # アクションプランをYouTubeタイトル風に変換
  def convert_to_youtube_title
    action_plan = params[:action_plan].to_s.strip                                    # アクションプランを取得

    if action_plan.blank?                                                            # 空の場合
      render json: { success: false, error: "アクションプランが必要です" }, status: :unprocessable_entity  # エラーを返す
      return                                                                         # 処理終了
    end

    result = GeminiService.convert_to_youtube_title(action_plan)                     # GeminiServiceで変換

    if result[:success]                                                              # 成功した場合
      render json: { success: true, title: result[:title] }                          # 成功レスポンス
    else                                                                             # 失敗した場合
      render json: { success: false, error: result[:error] }, status: :unprocessable_entity  # エラーレスポンス
    end
  end

  private

  # 動画を取得
  def set_post
    @post = Post.find(params[:id])                                                   # IDで検索
  rescue ActiveRecord::RecordNotFound                                                # 見つからない場合
    redirect_to posts_path, alert: t("posts.not_found")                              # 一覧へリダイレクト
  end

  # 自分のエントリーがあるかチェック
  def check_has_entries
    return if @post.has_entries_by?(current_user)                                    # エントリーがあればOK
    redirect_to @post, alert: "この動画にはあなたのエントリーがありません"            # 詳細へリダイレクト
  end

  # Strong Parameters
  def post_params
    params.require(:post).permit(:youtube_url)                                       # 許可パラメータ
  end

  # ユーザーでフィルターした投稿を取得
  def load_user_filtered_posts(base_scope)
    @filter_user = User.find_by(id: params[:user_id])                                # フィルターユーザーを取得
    return unless @filter_user                                                       # ユーザーがなければ終了

    post_ids = PostEntry.where(user_id: params[:user_id]).select(:post_id).distinct  # ユーザーのpost_idを取得
    @posts = base_scope.where(id: post_ids).recent.page(params[:page]).per(20)       # 投稿を取得
  end

  # チャンネルでフィルターした投稿を取得
  def load_channel_filtered_posts(base_scope)
    @filter_channel = params[:channel]                                               # フィルターチャンネル名を取得
    @posts = base_scope.where(youtube_channel_name: @filter_channel)                 # チャンネルで絞り込み
                       .recent.page(params[:page]).per(20)                           # ページネーション
  end

  # セクション表示用データを取得
  def load_section_data
    posts_with_achieved_ids = Post.with_achieved_entries.pluck(:id)                  # 達成済みエントリーありの投稿ID
    @featured_post = Post.find(posts_with_achieved_ids.sample) if posts_with_achieved_ids.present?  # ランダムで1件取得

    @popular_channels = Post.popular_channels(limit: 10)                             # 人気チャンネル
    @ranking_posts = Post.by_action_count(limit: 10)                                 # アクション数ランキング
    @user_ranking = User.by_achieved_count(limit: 10)                                # ユーザーランキング
    @recent_posts = Post.with_achieved_entries.recent.includes(:post_entries).limit(20)  # 最近の投稿
  end

  # Turbo Stream用のレスポンス
  def render_posts_page
    if @posts.present?                                                               # 投稿がある場合
      render partial: "posts/posts_page", locals: { posts: @posts }                  # パーシャルをレンダリング
    else                                                                             # 投稿がない場合
      head :ok                                                                       # 空レスポンス
    end
  end

  # create_with_actionのパラメータバリデーション
  def validate_create_with_action_params
    return { message: "動画URLが必要です", status: :unprocessable_entity } if params[:youtube_url].blank?  # URL必須
    return { message: "アクションプランが必要です", status: :unprocessable_entity } if params[:action_plan].blank?  # プラン必須
    return { message: "ログインが必要です", status: :unauthorized } unless user_signed_in?  # ログイン必須
    nil                                                                              # エラーなし
  end

  # PostEntryを構築
  def build_post_entry(post)
    post.post_entries.new(                                                           # 新しいエントリーを構築
      user: current_user,                                                            # 作成者
      content: params[:action_plan],                                                 # プラン内容
      deadline: 7.days.from_now.to_date,                                             # 期限（7日後）
      thumbnail_url: params[:thumbnail_s3_key]                                       # サムネイル
    )
  end

  # オートコンプリート用の候補を取得
  def search_suggestions(query)
    Post                                                                             # Postモデル
      .where("youtube_title ILIKE :q OR youtube_channel_name ILIKE :q", q: "%#{query}%")  # タイトルまたはチャンネル名で検索
      .limit(10)                                                                     # 最大10件
      .pluck(:youtube_title, :youtube_channel_name)                                  # タイトルとチャンネル名を取得
      .flatten                                                                       # 配列を平坦化
      .compact                                                                       # nilを除去
      .uniq                                                                          # 重複除去
      .select { |s| s.downcase.include?(query.downcase) }                            # クエリを含むものだけ
      .first(10)                                                                     # 最大10件
  end

  # 既存投稿を検索してJSON形式で返す
  def search_existing_posts(query)
    posts = Post.joins(:post_entries)                                                # エントリーと結合
                .where("youtube_title ILIKE :q OR youtube_channel_name ILIKE :q", q: "%#{query}%")  # 検索条件
                .distinct                                                            # 重複除去
                .order(created_at: :desc)                                            # 新しい順
                .limit(10)                                                           # 最大10件

    posts.map do |post|                                                              # 各投稿をJSON形式に変換
      {
        id: post.id,                                                                 # 投稿ID
        title: post.youtube_title,                                                   # タイトル
        channel_name: post.youtube_channel_name,                                     # チャンネル名
        thumbnail_url: post.youtube_thumbnail_url(size: :mqdefault),                 # サムネイルURL
        url: post_path(post),                                                        # 投稿URL
        entry_count: post.post_entries.count                                         # エントリー数
      }
    end
  end
end
