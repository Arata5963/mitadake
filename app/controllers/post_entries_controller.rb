# app/controllers/post_entries_controller.rb
# アクションプラン専用コントローラー
class PostEntriesController < ApplicationController
  include ActionView::RecordIdentifier

  before_action :authenticate_user!
  before_action :set_post
  before_action :set_entry, only: [ :edit, :update, :destroy, :achieve, :toggle_flame ]
  before_action :check_entry_owner, only: [ :edit, :update, :destroy, :achieve ]

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
    # サムネイル画像の処理
    thumbnail_data = params[:post_entry][:thumbnail_data]
    if thumbnail_data == "CLEAR"
      # 画像をクリア
      @entry.remove_thumbnail!
      @entry.save
    elsif thumbnail_data.present?
      process_thumbnail_data(thumbnail_data)
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
    if @entry.achieve!
      notice_message = @entry.achieved? ? "達成おめでとうございます！" : "未達成に戻しました"

      # デザインパラメータを保持してリダイレクト
      if params[:redirect_to] == "mypage" || request.referer&.include?("mypage")
        redirect_to mypage_path, notice: notice_message
      else
        # リファラーからdesignパラメータを取得
        design = extract_design_from_referer
        redirect_to post_path(@post, design: design), notice: notice_message
      end
    else
      redirect_to @post, alert: "達成処理に失敗しました"
    end
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

    # Base64データをデコードしてアップロード
    begin
      content_type = data.match(/data:(.*?);/)[1]
      extension = content_type.split("/").last
      decoded_data = Base64.decode64(data.split(",").last)

      # 一時ファイルを作成
      temp_file = Tempfile.new([ "thumbnail", ".#{extension}" ])
      temp_file.binmode
      temp_file.write(decoded_data)
      temp_file.rewind

      # CarrierWaveでアップロード
      @entry.thumbnail = temp_file
      @entry.save

      temp_file.close
      temp_file.unlink
    rescue StandardError => e
      Rails.logger.error "Thumbnail upload error: #{e.message}"
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
end
