# app/controllers/post_entries_controller.rb
# アクションプラン（PostEntry）に関するコントローラー
# - アクションプランの作成・編集・削除
# - 達成処理（感想・画像付き）
# - いいね機能
class PostEntriesController < ApplicationController
  include ActionView::RecordIdentifier

  before_action :authenticate_user!, except: [ :show_achievement ]
  before_action :set_post
  before_action :set_entry, only: [
    :edit, :update, :destroy, :achieve,
    :toggle_like, :show_achievement, :update_reflection
  ]
  before_action :check_entry_owner, only: [ :edit, :update, :destroy, :achieve, :update_reflection ]

  # ===== CRUD =====

  def create
    @entry = @post.post_entries.build(entry_params)
    @entry.user = current_user

    if @entry.save
      redirect_to @post, notice: "アクションプランを投稿しました"
    else
      redirect_to @post, alert: "投稿に失敗しました: #{@entry.errors.full_messages.join(', ')}"
    end
  end

  def edit
  end

  def update
    process_thumbnail_update
    process_video_change

    if @entry.update(entry_params)
      respond_to_update_success
    else
      respond_to_update_failure
    end
  end

  def destroy
    @entry.destroy
    redirect_after_destroy
  end

  # ===== 達成機能 =====

  # 達成処理（トグル / 感想・画像付き達成）
  def achieve
    respond_to do |format|
      format.html { handle_achieve_html }
      format.json { handle_achieve_json }
      format.turbo_stream { handle_achieve_turbo_stream }
    end
  end

  # 達成記録表示用データ取得（API）
  def show_achievement
    render json: build_achievement_json(@entry)
  end

  # 感想編集（API）
  def update_reflection
    @entry.update_reflection!(reflection_text: params[:reflection])
    render json: { success: true, reflection: @entry.reflection }
  rescue StandardError => e
    render json: { success: false, error: e.message }, status: :unprocessable_entity
  end

  # ===== いいね機能 =====

  def toggle_like
    existing_like = @entry.entry_likes.find_by(user: current_user)

    if existing_like
      existing_like.destroy
    else
      @entry.entry_likes.create(user: current_user)
    end

    respond_to do |format|
      format.html { redirect_back fallback_location: post_path(@post) }
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "like_button_#{@entry.id}",
          partial: "post_entries/like_button",
          locals: { post_entry: @entry }
        )
      end
    end
  end

  private

  # ===== Before Action =====

  def set_post
    @post = Post.find(params[:post_id])
  end

  def set_entry
    @entry = @post.post_entries.find(params[:id])
  end

  def check_entry_owner
    return if @entry.user == current_user

    redirect_to @post, alert: "他のユーザーのアクションプランは編集・削除できません"
  end

  def entry_params
    params.require(:post_entry).permit(:content, :deadline)
  end

  # ===== Update ヘルパー =====

  # サムネイル画像の更新処理
  def process_thumbnail_update
    thumbnail_s3_key = params[:post_entry][:thumbnail_s3_key]
    return if thumbnail_s3_key.blank?

    if thumbnail_s3_key == "CLEAR"
      @entry.update(thumbnail_url: nil)
    else
      @entry.update(thumbnail_url: thumbnail_s3_key)
    end
  end

  # 動画変更処理
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

  # ===== Destroy ヘルパー =====

  # 削除後のリダイレクト
  def redirect_after_destroy
    if params[:from] == "mypage" || request.referer&.include?("mypage")
      redirect_to mypage_path, notice: "アクションプランを削除しました"
    else
      redirect_to post_path(@post, design: extract_design_from_referer), notice: "アクションプランを削除しました"
    end
  end

  # ===== Achieve ヘルパー =====

  # HTML形式の達成処理（トグル）
  def handle_achieve_html
    if @entry.achieve!
      notice_message = @entry.achieved? ? "達成おめでとうございます！" : "未達成に戻しました"
      redirect_after_achieve(notice_message)
    else
      redirect_to @post, alert: "達成処理に失敗しました"
    end
  end

  # JSON形式の達成処理（モーダルからの達成）
  def handle_achieve_json
    if @entry.achieved?
      # 達成済み→未達成に戻す
      @entry.update!(achieved_at: nil, reflection: nil, result_image: nil)
      render json: { success: true, achieved: false }
    else
      # 未達成→達成（感想・画像付き）
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
      flash.now[:notice] = "達成おめでとうございます！🎉"
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

  # ===== JSON ヘルパー =====

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

  # ===== ユーティリティ =====

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
