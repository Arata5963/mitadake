# app/controllers/post_entries_controller.rb
# ==========================================
# アクションプラン（PostEntry）コントローラー
# ==========================================
#
# 【このクラスの役割】
# アクションプランの作成・編集・削除・達成処理を担当する。
# ユーザーが「○○をやる！」と宣言したプランを管理する。
#
# 【主な機能】
# 1. アクションプランのCRUD（作成・編集・削除）
# 2. 達成処理（感想・画像付き）
# 3. いいね機能
# 4. 達成記録の表示
#
# 【ルーティング】
# 全てのルートは posts/:post_id/entries の下にネストされている。
# - POST   /posts/:post_id/entries → create
# - GET    /posts/:post_id/entries/:id/edit → edit
# - PATCH  /posts/:post_id/entries/:id → update
# - DELETE /posts/:post_id/entries/:id → destroy
# - POST   /posts/:post_id/entries/:id/achieve → achieve
# - POST   /posts/:post_id/entries/:id/toggle_like → toggle_like
#
class PostEntriesController < ApplicationController
  # ActionView::RecordIdentifier を include すると dom_id メソッドが使える
  # dom_id(@entry) で "post_entry_123" のような ID 文字列を生成
  include ActionView::RecordIdentifier

  # ==========================================
  # before_action（各アクションの前に実行）
  # ==========================================

  # 達成記録表示以外はログイン必須
  before_action :authenticate_user!, except: [ :show_achievement ]

  # 親リソース（Post）を取得
  before_action :set_post

  # 対象のエントリーを取得
  before_action :set_entry, only: [
    :edit, :update, :destroy, :achieve,
    :toggle_like, :show_achievement, :update_reflection
  ]

  # 編集・更新・削除・達成は所有者のみ
  before_action :check_entry_owner, only: [ :edit, :update, :destroy, :achieve, :update_reflection ]

  # ==========================================
  # CRUDアクション
  # ==========================================

  # ------------------------------------------
  # アクションプラン作成
  # ------------------------------------------
  # 【ルート】POST /posts/:post_id/entries
  #
  # 【処理内容】
  # フォームから送信されたアクションプランを保存する。
  # 成功したら動画詳細ページにリダイレクト。
  #
  def create
    @entry = @post.post_entries.build(entry_params)
    @entry.user = current_user

    if @entry.save
      redirect_to @post, notice: "アクションプランを投稿しました"
    else
      redirect_to @post, alert: "投稿に失敗しました: #{@entry.errors.full_messages.join(', ')}"
    end
  end

  # ------------------------------------------
  # 編集画面
  # ------------------------------------------
  # 【ルート】GET /posts/:post_id/entries/:id/edit
  #
  def edit
    # @entry は set_entry で取得済み
    # ビュー: app/views/post_entries/edit.html.erb
  end

  # ------------------------------------------
  # 更新
  # ------------------------------------------
  # 【ルート】PATCH /posts/:post_id/entries/:id
  #
  # 【処理内容】
  # アクションプランの内容・期限・サムネイル・動画を更新する。
  # 複数のレスポンス形式に対応（HTML/JSON/Turbo Stream）。
  #
  def update
    # サムネイル画像の更新処理
    process_thumbnail_update

    # 動画の変更処理（別の動画に紐づけ直す）
    process_video_change

    if @entry.update(entry_params)
      respond_to_update_success
    else
      respond_to_update_failure
    end
  end

  # ------------------------------------------
  # 削除
  # ------------------------------------------
  # 【ルート】DELETE /posts/:post_id/entries/:id
  #
  def destroy
    @entry.destroy
    redirect_after_destroy
  end

  # ==========================================
  # 達成機能
  # ==========================================

  # ------------------------------------------
  # 達成処理（トグル / 感想・画像付き達成）
  # ------------------------------------------
  # 【ルート】POST /posts/:post_id/entries/:id/achieve
  #
  # 【処理内容】
  # - HTML形式: 達成状態をトグル（達成⇔未達成）
  # - JSON形式: 感想・画像付きで達成
  # - Turbo Stream形式: ページを部分更新
  #
  def achieve
    respond_to do |format|
      format.html { handle_achieve_html }
      format.json { handle_achieve_json }
      format.turbo_stream { handle_achieve_turbo_stream }
    end
  end

  # ------------------------------------------
  # 達成記録表示用データ取得（API）
  # ------------------------------------------
  # 【ルート】GET /posts/:post_id/entries/:id/show_achievement
  #
  # 【何をするアクション？】
  # 達成記録モーダルに表示するデータをJSON形式で返す。
  # 達成画像・感想・ユーザー情報などを含む。
  #
  def show_achievement
    render json: build_achievement_json(@entry)
  end

  # ------------------------------------------
  # 感想編集（API）
  # ------------------------------------------
  # 【ルート】PATCH /posts/:post_id/entries/:id/update_reflection
  #
  # 【何をするアクション？】
  # 達成後の振り返りコメントのみを更新する。
  #
  def update_reflection
    @entry.update_reflection!(reflection_text: params[:reflection])
    render json: { success: true, reflection: @entry.reflection }
  rescue StandardError => e
    render json: { success: false, error: e.message }, status: :unprocessable_entity
  end

  # ==========================================
  # いいね機能
  # ==========================================

  # ------------------------------------------
  # いいねトグル
  # ------------------------------------------
  # 【ルート】POST /posts/:post_id/entries/:id/toggle_like
  #
  # 【処理内容】
  # いいねしていなければ追加、していれば削除。
  # Turbo Streamでボタン部分だけ更新。
  #
  def toggle_like
    existing_like = @entry.entry_likes.find_by(user: current_user)

    if existing_like
      existing_like.destroy  # いいね解除
    else
      @entry.entry_likes.create(user: current_user)  # いいね追加
    end

    respond_to do |format|
      format.html { redirect_back fallback_location: post_path(@post) }
      format.turbo_stream do
        # 【turbo_stream.replace とは？】
        # Hotwireの機能。指定したIDの要素を新しい内容で置換する。
        # ページ全体をリロードせずに部分的に更新できる。
        render turbo_stream: turbo_stream.replace(
          "like_button_#{@entry.id}",
          partial: "post_entries/like_button",
          locals: { post_entry: @entry }
        )
      end
    end
  end

  private

  # ==========================================
  # Before Action メソッド
  # ==========================================

  # 親リソース（Post）を取得
  def set_post
    @post = Post.find(params[:post_id])
  end

  # 対象のエントリーを取得
  def set_entry
    @entry = @post.post_entries.find(params[:id])
  end

  # エントリーの所有者かチェック
  def check_entry_owner
    return if @entry.user == current_user

    redirect_to @post, alert: "他のユーザーのアクションプランは編集・削除できません"
  end

  # Strong Parameters
  def entry_params
    params.require(:post_entry).permit(:content, :deadline)
  end

  # ==========================================
  # Update ヘルパーメソッド
  # ==========================================

  # ------------------------------------------
  # サムネイル画像の更新処理
  # ------------------------------------------
  # 【処理内容】
  # - "CLEAR" が送られたら画像を削除
  # - S3キーが送られたら新しい画像に更新
  #
  def process_thumbnail_update
    thumbnail_s3_key = params[:post_entry][:thumbnail_s3_key]
    return if thumbnail_s3_key.blank?

    if thumbnail_s3_key == "CLEAR"
      @entry.update(thumbnail_url: nil)
    else
      @entry.update(thumbnail_url: thumbnail_s3_key)
    end
  end

  # ------------------------------------------
  # 動画変更処理
  # ------------------------------------------
  # 【処理内容】
  # アクションプランを別の動画に紐づけ直す。
  # 編集時に動画を変更したい場合に使用。
  #
  def process_video_change
    new_video_url = params[:post_entry][:new_video_url]
    return if new_video_url.blank?

    new_post = Post.find_or_create_by_video(youtube_url: new_video_url)
    if new_post&.persisted? && new_post.id != @entry.post_id
      @entry.post = new_post
      @post = new_post
    end
  rescue StandardError => e
    Rails.logger.error "Video change error: #{e.message}"
  end

  # 更新成功時のレスポンス
  def respond_to_update_success
    respond_to do |format|
      format.json do
        redirect_url = params[:from] == "mypage" ? mypage_path : post_path(@post)
        render json: { success: true, redirect_url: redirect_url }
      end
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          dom_id(@entry),
          partial: "post_entries/entry_card",
          locals: { entry: @entry }
        )
      end
      format.html do
        redirect_path = params[:from] == "mypage" ? mypage_path : @post
        redirect_to redirect_path, notice: "アクションプランを更新しました"
      end
    end
  end

  # 更新失敗時のレスポンス
  def respond_to_update_failure
    respond_to do |format|
      format.json do
        render json: { success: false, error: @entry.errors.full_messages.join(", ") }, status: :unprocessable_entity
      end
      format.turbo_stream { render :edit, status: :unprocessable_entity }
      format.html { render :edit, status: :unprocessable_entity }
    end
  end

  # ==========================================
  # Destroy ヘルパーメソッド
  # ==========================================

  # 削除後のリダイレクト
  def redirect_after_destroy
    if params[:from] == "mypage" || request.referer&.include?("mypage")
      redirect_to mypage_path, notice: "アクションプランを削除しました"
    else
      redirect_to post_path(@post, design: extract_design_from_referer), notice: "アクションプランを削除しました"
    end
  end

  # ==========================================
  # Achieve ヘルパーメソッド
  # ==========================================

  # HTML形式の達成処理（トグル）
  def handle_achieve_html
    if @entry.achieve!
      notice_message = @entry.achieved? ? "達成おめでとうございます！" : "未達成に戻しました"
      redirect_after_achieve(notice_message)
    else
      redirect_to @post, alert: "達成処理に失敗しました"
    end
  end

  # ------------------------------------------
  # JSON形式の達成処理
  # ------------------------------------------
  # 【処理内容】
  # - 達成済み → 未達成に戻す（感想・画像もクリア）
  # - 未達成 → 感想・画像付きで達成
  #
  def handle_achieve_json
    if @entry.achieved?
      # 達成済み → 未達成に戻す
      @entry.update!(achieved_at: nil, reflection: nil, result_image: nil)
      render json: { success: true, achieved: false }
    else
      # 未達成 → 達成（感想・画像付き）
      @entry.achieve_with_reflection!(
        reflection_text: params[:reflection],
        result_image_s3_key: params[:result_image_s3_key]
      )
      render json: { success: true, achieved: true, entry: entry_json(@entry) }
    end
  rescue StandardError => e
    render json: { success: false, error: e.message }, status: :unprocessable_entity
  end

  # Turbo Stream形式の達成処理
  def handle_achieve_turbo_stream
    if @entry.achieved?
      @entry.update!(achieved_at: nil, reflection: nil, result_image: nil)
      flash.now[:notice] = "未達成に戻しました"
    else
      @entry.achieve_with_reflection!(
        reflection_text: params[:reflection],
        result_image_s3_key: params[:result_image_s3_key]
      )
      flash.now[:notice] = "達成おめでとうございます！"
    end
  rescue StandardError => e
    flash.now[:alert] = e.message
  end

  # 達成後のリダイレクト
  def redirect_after_achieve(notice_message)
    if params[:redirect_to] == "mypage" || request.referer&.include?("mypage")
      redirect_to mypage_path, notice: notice_message
    else
      redirect_to post_path(@post, design: extract_design_from_referer), notice: notice_message
    end
  end

  # ==========================================
  # JSON ヘルパーメソッド
  # ==========================================

  # 達成記録のJSON構造を構築
  def build_achievement_json(entry)
    {
      id: entry.id,
      content: entry.content,
      reflection: entry.reflection,
      achieved_at: entry.achieved_at&.strftime("%Y年%m月%d日"),
      result_image_url: entry.signed_result_image_url,
      fallback_thumbnail_url: entry.signed_thumbnail_url || youtube_thumbnail_url(entry.post),
      post: {
        id: entry.post.id,
        title: entry.post.youtube_title,
        url: post_path(entry.post)
      },
      user: {
        name: entry.user&.name,
        avatar_url: entry.user&.avatar&.url
      },
      can_edit: user_signed_in? && entry.user == current_user
    }
  end

  # エントリーのJSON構造を構築
  def entry_json(entry)
    {
      id: entry.id,
      content: entry.content,
      reflection: entry.reflection,
      achieved_at: entry.achieved_at&.strftime("%Y年%m月%d日"),
      result_image_url: entry.signed_result_image_url,
      display_thumbnail_url: entry.display_result_thumbnail_url
    }
  end

  # ==========================================
  # ユーティリティメソッド
  # ==========================================

  # リファラーからデザインパラメータを抽出
  def extract_design_from_referer
    return nil unless request.referer

    uri = URI.parse(request.referer)
    Rack::Utils.parse_query(uri.query)["design"]
  rescue URI::InvalidURIError
    nil
  end

  # YouTubeサムネイルURLを生成
  def youtube_thumbnail_url(post)
    "https://i.ytimg.com/vi/#{post.youtube_video_id}/mqdefault.jpg"
  end
end
