class UsersController < ApplicationController
  before_action :authenticate_user!, only: [ :edit, :update ]

  def show
    # IDがあれば他ユーザー、なければ自分
    if params[:id]
      @user = User.find(params[:id])
      @is_own_page = user_signed_in? && @user == current_user

      # 自分自身の場合はマイページにリダイレクト
      if @is_own_page
        redirect_to mypage_path
        return
      end

      # 統計
      @total_achievements = @user.achievements.count

      # 他のユーザーの投稿一覧（そのユーザーがエントリーを持つPost）
      user_post_ids = PostEntry.where(user: @user).select(:post_id).distinct
      @user_posts = Post.where(id: user_post_ids)
                        .includes(:post_entries)
                        .recent
    else
      # ログイン必須
      authenticate_user!
      @user = current_user
      @is_own_page = true

      # 統計
      @total_achievements = @user.achievements.count
      today = Date.current

      # ユーザーの投稿一覧（自分がエントリーを持つPost）
      user_post_ids = PostEntry.where(user: @user).select(:post_id).distinct
      @user_posts = Post.where(id: user_post_ids)
                        .includes(:post_entries)
                        .recent

      # ===== タスクタブ用データ（PostEntry単位） =====
      action_entries = PostEntry.where(user: @user)
                                .where.not(deadline: nil)
                                .includes(:post)

      # 今日のタスク
      @todays_tasks = action_entries.where(achieved_at: nil)
                                    .where(deadline: today)
                                    .order(deadline: :asc)

      # 期限切れタスク
      @overdue_tasks = action_entries.where(achieved_at: nil)
                                     .where("post_entries.deadline < ?", today)
                                     .order(deadline: :asc)

      # 今後のタスク
      @upcoming_tasks = action_entries.where(achieved_at: nil)
                                      .where("post_entries.deadline > ?", today)
                                      .order(deadline: :asc)

      # 達成済みタスク
      @completed_tasks = action_entries.where.not(achieved_at: nil)
                                       .order(achieved_at: :desc)
                                       .limit(20)

      # エントリー統計
      @total_entries = PostEntry.where(user: @user).count

      # 過去30日間の活動データ（草用）
      @activity_data = PostEntry.where(user: @user)
                                .where("created_at >= ?", 30.days.ago)
                                .group("DATE(created_at)")
                                .count

      # 連続記録
      @streak = calculate_streak(@user)
    end
  end

  def edit
    @user = current_user
  end

  def update
    @user = current_user

    if @user.update(user_params)
      redirect_to mypage_path, notice: "プロフィールを更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :avatar, :avatar_cache, :favorite_quote, :favorite_quote_url)
  end

  def calculate_streak(user)
    # 過去の活動日を取得（エントリー作成日ベース）
    activity_dates = PostEntry.where(user: user)
                              .select("DATE(created_at) as activity_date")
                              .distinct
                              .order(Arel.sql("DATE(created_at) DESC"))
                              .pluck(Arel.sql("DATE(created_at)"))

    return 0 if activity_dates.empty?

    streak = 0
    today = Date.current
    check_date = today

    # 今日または昨日から連続をカウント
    unless activity_dates.include?(today)
      check_date = today - 1.day
      return 0 unless activity_dates.include?(check_date)
    end

    activity_dates.each do |date|
      if date == check_date
        streak += 1
        check_date -= 1.day
      elsif date < check_date
        break
      end
    end

    streak
  end
end
