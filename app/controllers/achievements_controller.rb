# app/controllers/achievements_controller.rb
# NOTE: In the new video-based structure, achievements are managed at PostEntry level
# via PostEntriesController#achieve. This controller is kept for backwards compatibility
# and for creating Achievement records for statistics.
class AchievementsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_post

  def create
    # Check if user has any unachieved entries for this post
    user_entries = @post.post_entries.where(user: current_user)
    unachieved_entries = user_entries.where(achieved_at: nil)

    if unachieved_entries.empty?
      respond_to do |format|
        format.html { redirect_to @post, alert: "No action entries to achieve" }
        format.turbo_stream { redirect_to @post, alert: "No action entries to achieve" }
      end
      return
    end

    ActiveRecord::Base.transaction do
      # Mark all unachieved action entries as achieved
      unachieved_entries.each do |entry|
        entry.achieve!  # これでサムネイル生成ジョブも起動される
      end

      # Create Achievement record for statistics
      current_user.achievements.create!(
        post: @post,
        achieved_at: Date.current
      )
    end

    # Get recommended posts
    @recommended_posts = @post.recommended_posts(limit: 3)

    respond_to do |format|
      format.html { redirect_to @post, notice: t("achievements.create.success") }
      format.turbo_stream
    end
  rescue ActiveRecord::RecordInvalid => e
    respond_to do |format|
      format.html { redirect_to @post, alert: e.message }
      format.turbo_stream { redirect_to @post, alert: e.message }
    end
  end

  def destroy
    redirect_to @post, alert: "Achievement records cannot be undone"
  end

  private

  def set_post
    @post = Post.find(params[:post_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to posts_path, alert: t("posts.not_found")
  end
end
