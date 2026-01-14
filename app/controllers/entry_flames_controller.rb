# app/controllers/entry_flames_controller.rb
class EntryFlamesController < ApplicationController
  # ==== フィルター設定 ====
  before_action :authenticate_user!
  before_action :set_post
  before_action :set_post_entry

  # ==== アクション定義 ====

  # 炎マーク作成処理
  def create
    # 既に炎マーク済みの場合は何もしない
    if @post_entry.flamed_by?(current_user)
      respond_to do |format|
        format.html { redirect_to posts_path, alert: t("entry_flames.create.already_flamed") }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "flame_button_#{@post_entry.id}",
            partial: "entry_flames/flame_button",
            locals: { post_entry: @post_entry }
          )
        end
      end
      return
    end

    @flame = @post_entry.entry_flames.build(user: current_user)

    if @flame.save
      respond_to do |format|
        format.html { redirect_to posts_path, notice: t("entry_flames.create.success") }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "flame_button_#{@post_entry.id}",
            partial: "entry_flames/flame_button",
            locals: { post_entry: @post_entry }
          )
        end
      end
    else
      respond_to do |format|
        format.html { redirect_to posts_path, alert: @flame.errors.full_messages.first }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "flame_button_#{@post_entry.id}",
            partial: "entry_flames/flame_button",
            locals: { post_entry: @post_entry }
          )
        end
      end
    end
  end

  # 炎マーク削除処理
  def destroy
    @flame = @post_entry.entry_flames.find_by(user: current_user)

    if @flame
      @flame.destroy

      respond_to do |format|
        format.html { redirect_to posts_path, notice: t("entry_flames.destroy.success") }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "flame_button_#{@post_entry.id}",
            partial: "entry_flames/flame_button",
            locals: { post_entry: @post_entry }
          )
        end
      end
    else
      respond_to do |format|
        format.html { redirect_to posts_path, alert: t("entry_flames.not_found") }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "flame_button_#{@post_entry.id}",
            partial: "entry_flames/flame_button",
            locals: { post_entry: @post_entry }
          )
        end
      end
    end
  end

  private

  def set_post
    @post = Post.find(params[:post_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to posts_path, alert: t("posts.not_found")
  end

  def set_post_entry
    @post_entry = @post.post_entries.find(params[:post_entry_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to posts_path, alert: t("post_entries.not_found")
  end
end
