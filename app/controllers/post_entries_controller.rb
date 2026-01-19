# app/controllers/post_entries_controller.rb
# アクションプラン専用コントローラー
class PostEntriesController < ApplicationController
  include ActionView::RecordIdentifier

  before_action :authenticate_user!, except: [ :show_achievement ]
  before_action :set_post
  before_action :set_entry, only: [ :edit, :update, :destroy, :achieve, :toggle_flame, :show_achievement, :update_reflection ]
  before_action :check_entry_owner, only: [ :edit, :update, :destroy, :achieve, :update_reflection ]

  def create
    @entry = @post.post_entries.build(entry_params)
    @entry.user = current_user
    @entry.anonymous = params[:post_entry][:anonymous] == "1"

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

    # サムネイル画像の処理
    thumbnail_data = params[:post_entry][:thumbnail_data]
    Rails.logger.info "[Update] thumbnail_data present: #{thumbnail_data.present?}, value: #{thumbnail_data.to_s[0..50]}..."

    if thumbnail_data == "CLEAR"
      # 画像をクリア
      Rails.logger.info "[Update] Clearing thumbnail"
      @entry.thumbnail_url = nil
      @entry.save
    elsif thumbnail_data.present?
      Rails.logger.info "[Update] Processing new thumbnail"
      process_thumbnail_data(thumbnail_data)
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
        name: @entry.display_user_name,
        avatar_url: @entry.display_avatar&.url
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

  def toggle_flame
    existing_flame = @entry.entry_flames.find_by(user: current_user)

    if existing_flame
      existing_flame.destroy
    else
      @entry.entry_flames.create(user: current_user)
    end

    redirect_back fallback_location: post_path(@post)
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

  def process_thumbnail_data(data)
    return unless data.present? && data.start_with?("data:image")

    Rails.logger.info "[Thumbnail] Processing thumbnail data (length: #{data.length})"

    begin
      # Base64データをパース
      matches = data.match(/\Adata:(.*?);base64,(.*)\z/m)
      return unless matches

      content_type = matches[1]
      decoded_data = Base64.decode64(matches[2])

      Rails.logger.info "[Thumbnail] Decoded data size: #{decoded_data.bytesize} bytes"

      # ファイル拡張子を決定
      extension = case content_type
      when "image/jpeg" then "jpg"
      when "image/png" then "png"
      when "image/webp" then "webp"
      else "jpg"
      end

      # S3にアップロード
      filename = "thumbnails/#{@entry.user_id}/#{SecureRandom.uuid}.#{extension}"

      s3_client = Aws::S3::Client.new
      s3_client.put_object(
        bucket: ENV["AWS_BUCKET"],
        key: filename,
        body: decoded_data,
        content_type: content_type
      )

      # thumbnail_urlカラムに保存
      @entry.thumbnail_url = filename
      if @entry.save
        Rails.logger.info "[Thumbnail] Successfully saved thumbnail for entry #{@entry.id}: #{filename}"
      else
        Rails.logger.error "[Thumbnail] Failed to save: #{@entry.errors.full_messages.join(', ')}"
      end
    rescue StandardError => e
      Rails.logger.error "[Thumbnail] Upload error: #{e.message}"
      Rails.logger.error e.backtrace.first(5).join("\n")
    end
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
