# app/controllers/users_controller.rb
# ユーザー関連のコントローラー
#
# 主な機能:
# - マイページ表示（/mypage）: 自分のタスク管理・統計表示
# - 他ユーザープロフィール表示（/users/:id）
# - プロフィール編集（/edit_profile）
class UsersController < ApplicationController
  before_action :authenticate_user!, only: [ :edit, :update ]

  # マイページ または 他ユーザープロフィール表示
  # @route GET /mypage（自分）, GET /users/:id（他ユーザー）
  def show
    if params[:id]
      show_other_user
    else
      show_my_page
    end
  end

  # プロフィール編集画面
  # @route GET /edit_profile
  def edit
    @user = current_user
  end

  # プロフィール更新
  # @route PATCH /mypage
  def update
    @user = current_user

    if @user.update(user_params)
      redirect_to mypage_path, notice: "プロフィールを更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  # ===== Show ヘルパー =====

  # 他ユーザーのプロフィール表示
  def show_other_user
    @user = User.find(params[:id])
    @is_own_page = user_signed_in? && @user == current_user

    # 自分自身の場合はマイページにリダイレクト
    if @is_own_page
      redirect_to mypage_path
      return
    end

    # 他ユーザーの投稿一覧を取得
    load_user_posts(@user)
  end

  # 自分のマイページ表示
  def show_my_page
    authenticate_user!
    @user = current_user
    @is_own_page = true

    load_user_posts(@user)
    load_task_data(@user)
    load_statistics(@user)
  end

  # ユーザーの投稿一覧を取得
  # @param user [User] 対象ユーザー
  def load_user_posts(user)
    user_post_ids = PostEntry.where(user: user).select(:post_id).distinct
    @user_posts = Post.where(id: user_post_ids)
                      .includes(:post_entries)
                      .recent
  end

  # タスクタブ用データを取得（期限別に分類）
  # @param user [User] 対象ユーザー
  def load_task_data(user)
    today = Date.current
    action_entries = PostEntry.where(user: user)
                              .where.not(deadline: nil)
                              .includes(:post)

    # 今日が期限のタスク
    @todays_tasks = action_entries.where(achieved_at: nil)
                                  .where(deadline: today)
                                  .order(deadline: :asc)

    # 期限切れのタスク
    @overdue_tasks = action_entries.where(achieved_at: nil)
                                   .where("post_entries.deadline < ?", today)
                                   .order(deadline: :asc)

    # 今後のタスク（明日以降が期限）
    @upcoming_tasks = action_entries.where(achieved_at: nil)
                                    .where("post_entries.deadline > ?", today)
                                    .order(deadline: :asc)

    # 達成済みタスク（直近20件）
    @completed_tasks = action_entries.where.not(achieved_at: nil)
                                     .order(achieved_at: :desc)
                                     .limit(20)
  end

  # 統計情報を取得
  # @param user [User] 対象ユーザー
  def load_statistics(user)
    # 総エントリー数
    @total_entries = PostEntry.where(user: user).count

    # 過去30日間の活動データ（GitHub風の草表示用）
    @activity_data = PostEntry.where(user: user)
                              .where("created_at >= ?", 30.days.ago)
                              .group("DATE(created_at)")
                              .count

    # 連続活動日数
    @streak = calculate_streak(user)
  end

  def user_params
    params.require(:user).permit(:name, :avatar, :avatar_cache, :favorite_quote, :favorite_quote_url)
  end

  # 連続活動日数を計算
  # @param user [User] 対象ユーザー
  # @return [Integer] 連続日数（今日or昨日から遡って連続した活動日数）
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
