# app/controllers/post_entries_controller.rb
# アクションプラン専用コントローラー
class PostEntriesController < ApplicationController
  include ActionView::RecordIdentifier

  before_action :authenticate_user!
  before_action :set_post
  before_action :set_entry, only: [ :edit, :update, :destroy, :achieve ]
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
    if @entry.update(entry_params)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            dom_id(@entry),
            partial: "post_entries/entry_card",
            locals: { entry: @entry }
          )
        end
        format.html { redirect_to @post, notice: "アクションプランを更新しました" }
      end
    else
      respond_to do |format|
        format.turbo_stream { render :edit, status: :unprocessable_entity }
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @entry.destroy
    redirect_to @post, notice: "アクションプランを削除しました"
  end

  def achieve
    if @entry.achieve!
      notice_message = @entry.achieved? ? "達成おめでとうございます！" : "未達成に戻しました"
      redirect_url = params[:redirect_to] == "mypage" ? mypage_path : request.referer || @post

      respond_to do |format|
        format.turbo_stream do
          if request.referer&.include?("mypage") || params[:redirect_to] == "mypage"
            redirect_to mypage_path, notice: notice_message
          else
            render turbo_stream: turbo_stream.replace(
              dom_id(@entry),
              partial: "post_entries/entry_card",
              locals: { entry: @entry }
            )
          end
        end
        format.html { redirect_to redirect_url, notice: notice_message }
      end
    else
      respond_to do |format|
        format.turbo_stream { head :unprocessable_entity }
        format.html { redirect_to @post, alert: "達成処理に失敗しました" }
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
end
