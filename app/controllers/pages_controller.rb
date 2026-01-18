class PagesController < ApplicationController
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
end
