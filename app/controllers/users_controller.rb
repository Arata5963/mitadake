# ユーザーコントローラー
# マイページ・他ユーザープロフィール・プロフィール編集を担当

class UsersController < ApplicationController
  before_action :authenticate_user!, only: [ :edit, :update, :pending_actions, :achieved_actions ]  # 編集系はログイン必須

  # マイページまたは他ユーザープロフィール表示
  def show
    if params[:id]                                         # IDパラメータがある場合
      show_other_user                                      # 他ユーザーのプロフィール
    else                                                   # IDパラメータがない場合
      show_my_page                                         # 自分のマイページ
    end
  end

  # プロフィール編集画面
  def edit
    @user = current_user                                   # 現在のユーザーを取得
  end

  # プロフィール・アカウント設定更新
  def update
    @user = current_user                                   # 現在のユーザーを取得
    needs_password = password_change_requested? || email_change_requested?  # パスワード/メール変更があるか

    if needs_password                                      # パスワード/メール変更がある場合
      if @user.update_with_password(user_params_with_password)  # current_password必須で更新
        bypass_sign_in(@user)                              # パスワード変更後も再ログイン不要
        redirect_to mypage_path, notice: "プロフィールを更新しました"  # マイページへリダイレクト
      else                                                 # 更新失敗
        render :edit, status: :unprocessable_entity        # 編集画面を再表示
      end
    else                                                   # パスワード/メール変更がない場合
      if @user.update(user_params)                         # 通常のupdateで更新
        redirect_to mypage_path, notice: "プロフィールを更新しました"  # マイページへリダイレクト
      else                                                 # 更新失敗
        render :edit, status: :unprocessable_entity        # 編集画面を再表示
      end
    end
  end

  # 挑戦中のアクション一覧
  def pending_actions
    @user = current_user                                   # 現在のユーザーを取得
    @entries = @user.post_entries.not_achieved.includes(:post).order(created_at: :desc)  # 未達成エントリー取得
  end

  # 達成したアクション一覧
  def achieved_actions
    @user = current_user                                   # 現在のユーザーを取得
    @entries = @user.post_entries.achieved.includes(:post).order(achieved_at: :desc)  # 達成済みエントリー取得
  end

  private

  # 他ユーザーのプロフィール表示
  def show_other_user
    @user = User.find(params[:id])                         # 指定IDのユーザーを取得
    @is_own_page = user_signed_in? && @user == current_user  # 自分自身かどうか

    if @is_own_page                                        # 自分自身の場合
      redirect_to mypage_path                              # マイページへリダイレクト
      return                                               # 処理終了
    end

    load_user_posts(@user)                                 # ユーザーの投稿一覧を取得
  end

  # 自分のマイページ表示
  def show_my_page
    authenticate_user!                                     # ログイン必須
    @user = current_user                                   # 現在のユーザーを取得
    @is_own_page = true                                    # 自分のページフラグ

    load_user_posts(@user)                                 # 投稿一覧を取得
    load_task_data(@user)                                  # タスク（期限別）を取得
    load_statistics(@user)                                 # 統計情報を取得
  end

  # ユーザーの投稿一覧を取得
  def load_user_posts(user)
    user_post_ids = PostEntry.where(user: user).select(:post_id).distinct  # ユーザーのpost_idを取得
    @user_posts = Post.where(id: user_post_ids)            # 該当するPostを取得
                      .includes(:post_entries)             # N+1クエリ対策
                      .recent                              # 新しい順
  end

  # タスクタブ用データを取得
  def load_task_data(user)
    today = Date.current                                   # 今日の日付

    action_entries = PostEntry.where(user: user)           # ユーザーのエントリー
                              .where.not(deadline: nil)    # 期限があるもののみ
                              .includes(:post)             # N+1クエリ対策

    @todays_tasks = action_entries.where(achieved_at: nil)  # 今日が期限のタスク
                                  .where(deadline: today)   # 期限が今日
                                  .order(deadline: :asc)    # 期限順

    @overdue_tasks = action_entries.where(achieved_at: nil)  # 期限切れのタスク
                                   .where("post_entries.deadline < ?", today)  # 期限が過去
                                   .order(deadline: :asc)   # 期限順

    @upcoming_tasks = action_entries.where(achieved_at: nil)  # 今後のタスク
                                    .where("post_entries.deadline > ?", today)  # 期限が明日以降
                                    .order(deadline: :asc)  # 期限順

    @completed_tasks = action_entries.where.not(achieved_at: nil)  # 達成済みタスク
                                     .order(achieved_at: :desc)    # 達成日時順
                                     .limit(20)             # 直近20件
  end

  # 統計情報を取得
  def load_statistics(user)
    @total_entries = PostEntry.where(user: user).count     # 総エントリー数

    @activity_data = PostEntry.where(user: user)           # 過去30日間の活動データ
                              .where("created_at >= ?", 30.days.ago)  # 30日以内
                              .group("DATE(created_at)")   # 日付でグループ化
                              .count                       # 件数をカウント

    @streak = calculate_streak(user)                       # 連続活動日数
  end

  # Strong Parameters（プロフィールのみ）
  def user_params
    params.require(:user).permit(:name, :avatar, :avatar_cache, :favorite_quote_url)  # 許可パラメータ
  end

  # Strong Parameters（パスワード変更含む）
  def user_params_with_password
    params.require(:user).permit(                          # 許可パラメータ
      :name, :avatar, :avatar_cache, :favorite_quote_url,  # プロフィール
      :email, :password, :password_confirmation, :current_password  # 認証情報
    )
  end

  # パスワード変更がリクエストされているか
  def password_change_requested?
    params[:user][:password].present?                      # パスワードが入力されているか
  end

  # メールアドレス変更がリクエストされているか
  def email_change_requested?
    params[:user][:email].present? && params[:user][:email] != @user.email  # メールが変更されているか
  end

  # 連続活動日数を計算
  def calculate_streak(user)
    activity_dates = PostEntry.where(user: user)           # ユーザーの活動日を取得
                              .select("DATE(created_at) as activity_date")  # 日付のみ抽出
                              .distinct                    # 重複除去
                              .order(Arel.sql("DATE(created_at) DESC"))  # 降順
                              .pluck(Arel.sql("DATE(created_at)"))  # 配列として取得

    return 0 if activity_dates.empty?                      # 活動がなければ0

    streak = 0                                             # 連続日数カウンター
    today = Date.current                                   # 今日の日付
    check_date = today                                     # チェック開始日

    unless activity_dates.include?(today)                  # 今日活動していない場合
      check_date = today - 1.day                           # 昨日からチェック開始
      return 0 unless activity_dates.include?(check_date)  # 昨日も活動していなければ0
    end

    activity_dates.each do |date|                          # 活動日を順番にチェック
      if date == check_date                                # チェック日と一致
        streak += 1                                        # 連続日数を加算
        check_date -= 1.day                                # 1日前をチェック
      elsif date < check_date                              # 連続が途切れた
        break                                              # ループ終了
      end
    end

    streak                                                 # 連続日数を返す
  end
end
