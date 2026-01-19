# app/controllers/post_entries_controller.rb
# アクションプラン専用コントローラー
class PostEntriesController < ApplicationController
  include ActionView::RecordIdentifier

  before_action :authenticate_user!, except: [ :show_achievement ]
  before_action :set_post
  before_action :set_entry, only: [ :edit, :update, :destroy, :achieve, :toggle_like, :show_achievement, :update_reflection ]
  before_action :check_entry_owner, only: [ :edit, :update, :destroy, :achieve, :update_reflection ]

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
    Rails.logger.info "[Update] Entry #{@entry.id} - params: #{params[:post_entry].keys}"

    # サムネイル画像の処理（署名付きURL方式：S3キーを直接受け取る）
    thumbnail_s3_key = params[:post_entry][:thumbnail_s3_key]
    Rails.logger.info "[Update] thumbnail_s3_key: #{thumbnail_s3_key.to_s[0..50]}..."

    if thumbnail_s3_key == "CLEAR"
      # 画像をクリア
      Rails.logger.info "[Update] Clearing thumbnail"
      @entry.thumbnail_url = nil
      @entry.save
    elsif thumbnail_s3_key.present?
      # S3キーを直接保存（Base64処理不要）
      Rails.logger.info "[Update] Setting thumbnail S3 key"
      @entry.thumbnail_url = thumbnail_s3_key
      @entry.save
    else
      Rails.logger.info "[Update] No thumbnail data provided"
    end

    # 動画変更の処理
    new_video_url = params[:post_entry][:new_video_url]
    if new_video_url.present?
      handle_video_change(new_video_url)
    end

    if @entry.update(entry_params)
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
          if params[:from] == "mypage"
            redirect_to mypage_path, notice: "アクションプランを更新しました"
          else
            redirect_to @post, notice: "アクションプランを更新しました"
          end
        end
      end
    else
      respond_to do |format|
        format.json do
          render json: { success: false, error: @entry.errors.full_messages.join(", ") }, status: :unprocessable_entity
        end
        format.turbo_stream { render :edit, status: :unprocessable_entity }
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @entry.destroy
    if params[:from] == "mypage" || request.referer&.include?("mypage")
      redirect_to mypage_path, notice: "アクションプランを削除しました"
    else
      design = extract_design_from_referer
      redirect_to post_path(@post, design: design), notice: "アクションプランを削除しました"
    end
  end

  def achieve
    respond_to do |format|
      # HTML: 従来のトグル動作
      format.html do
        if @entry.achieve!
          notice_message = @entry.achieved? ? "達成おめでとうございます！" : "未達成に戻しました"

          if params[:redirect_to] == "mypage" || request.referer&.include?("mypage")
            redirect_to mypage_path, notice: notice_message
          else
            design = extract_design_from_referer
            redirect_to post_path(@post, design: design), notice: notice_message
          end
        else
          redirect_to @post, alert: "達成処理に失敗しました"
        end
      end

      # JSON: モーダルからの達成（感想・画像付き）
      format.json do
        if @entry.achieved?
          # 既に達成済み→未達成に戻す
          @entry.update!(achieved_at: nil, reflection: nil, result_image: nil)
          render json: { success: true, achieved: false }
        else
          # 未達成→達成にする（感想・画像付き）
          # 署名付きURL方式: S3キーを直接受け取る
          @entry.achieve_with_reflection!(
            reflection_text: params[:reflection],
            result_image_s3_key: params[:result_image_s3_key]
          )
          render json: {
            success: true,
            achieved: true,
            entry: entry_json(@entry)
          }
        end
      rescue StandardError => e
        render json: { success: false, error: e.message }, status: :unprocessable_entity
      end

      # Turbo Stream: フラッシュメッセージ付きで達成
      format.turbo_stream do
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
    end
  end

  # 達成記録表示用データ取得
  def show_achievement
    render json: {
      id: @entry.id,
      content: @entry.content,
      reflection: @entry.reflection,
      achieved_at: @entry.achieved_at&.strftime("%Y年%m月%d日"),
      result_image_url: @entry.signed_result_image_url,
      fallback_thumbnail_url: @entry.signed_thumbnail_url || youtube_thumbnail_url(@entry.post),
      post: {
        id: @entry.post.id,
        title: @entry.post.youtube_title,
        url: post_path(@entry.post)
      },
      user: {
        name: @entry.user&.name,
        avatar_url: @entry.user&.avatar&.url
      },
      can_edit: user_signed_in? && @entry.user == current_user
    }
  end

  # 感想編集
  def update_reflection
    @entry.update_reflection!(reflection_text: params[:reflection])
    render json: { success: true, reflection: @entry.reflection }
  rescue StandardError => e
    render json: { success: false, error: e.message }, status: :unprocessable_entity
  end

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

  def set_post
    @post = Post.find(params[:post_id])
  end

  def set_entry
    @entry = @post.post_entries.find(params[:id])
  end

  def check_entry_owner
    unless @entry.user == current_user
      redirect_to @post, alert: "他のユーザーのアクションプランは編集・削除できません"
    end
  end

  def entry_params
    params.require(:post_entry).permit(:content, :deadline)
  end

  def extract_design_from_referer
    return nil unless request.referer
    uri = URI.parse(request.referer)
    query = Rack::Utils.parse_query(uri.query)
    query["design"]
  rescue URI::InvalidURIError
    nil
  end

  def handle_video_change(youtube_url)
    # 新しいPostを取得または作成
    new_post = Post.find_or_create_by_video(youtube_url: youtube_url)
    if new_post&.persisted? && new_post.id != @entry.post_id
      @entry.post = new_post
      @post = new_post
    end
  rescue StandardError => e
    Rails.logger.error "Video change error: #{e.message}"
  end

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

  def youtube_thumbnail_url(post)
    "https://i.ytimg.com/vi/#{post.youtube_video_id}/mqdefault.jpg"
  end
end
