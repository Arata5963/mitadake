class PagesController < ApplicationController
  def landing
    @ranking_posts = Post.by_action_count(limit: 5)
    @achieved_entries = PostEntry.achieved
                                 .includes(:user, :post)
                                 .where.not(thumbnail_url: [nil, ""])
                                 .order(achieved_at: :desc)
                                 .limit(3)
  end

  def terms
  end

  def privacy
  end

  def countdown_design
    render "post_entries/designs/countdown_comparison", layout: "application"
  end

  def action_plan_design
    render "users/designs/action_plan_comparison", layout: "application"
  end

  def achieved_videos_design
    render "users/designs/achieved_videos_comparison", layout: "application"
  end

  def new_post_design
    render "posts/designs/new_post_comparison", layout: "application"
  end

  def landing_design
    @ranking_posts = Post.by_action_count(limit: 5)
    render "pages/designs/landing_comparison", layout: "landing"
  end

  def landing_a_design
    @ranking_posts = Post.by_action_count(limit: 5)
    render "pages/designs/landing_a_minimal", layout: "landing"
  end

  def landing_b_design
    @ranking_posts = Post.by_action_count(limit: 5)
    render "pages/designs/landing_b_visual", layout: "landing"
  end

  def landing_c_design
    @ranking_posts = Post.by_action_count(limit: 5)
    render "pages/designs/landing_c_story", layout: "landing"
  end
end
