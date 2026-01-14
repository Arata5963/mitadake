class BookshelvesController < ApplicationController
  def show
    if params[:id]
      @user = User.find(params[:id])
      @is_own_page = user_signed_in? && @user == current_user

      if @is_own_page
        redirect_to bookshelf_path
        return
      end
    else
      authenticate_user!
      @user = current_user
      @is_own_page = true
    end

    # 達成済み動画を取得（重複を除く、達成日時の新しい順）
    # サブクエリで各post_idの最新achieved_atを取得
    latest_achieved = @user.post_entries
                           .achieved
                           .select("post_id, MAX(achieved_at) as latest_achieved_at")
                           .group(:post_id)

    @posts = Post.joins("INNER JOIN (#{latest_achieved.to_sql}) AS latest ON posts.id = latest.post_id")
                 .order("latest.latest_achieved_at DESC")
                 .page(params[:page])
                 .per(18)

    # 総達成数（動画の重複を除く）
    @total_count = @user.post_entries.achieved.select(:post_id).distinct.count
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: t("users.not_found")
  end
end
