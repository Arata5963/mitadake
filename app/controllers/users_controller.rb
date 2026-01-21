# app/controllers/users_controller.rb
# ==========================================
# ユーザー関連コントローラー
# ==========================================
#
# 【このクラスの役割】
# マイページ・他ユーザープロフィール・プロフィール編集を担当。
#
# 【主な機能】
# 1. マイページ表示（/mypage）: 自分のタスク管理・統計表示
# 2. 他ユーザープロフィール表示（/users/:id）
# 3. プロフィール編集（/edit_profile）
#
# 【ルーティング】
# - GET /mypage → show（自分のマイページ）
# - GET /users/:id → show（他ユーザープロフィール）
# - GET /edit_profile → edit（編集画面）
# - PATCH /mypage → update（プロフィール更新）
#
class UsersController < ApplicationController

  # プロフィール編集はログイン必須
  # 閲覧系（show）は認証不要だが、マイページは内部で認証チェック
  before_action :authenticate_user!, only: [ :edit, :update ]

  # ------------------------------------------
  # マイページ または 他ユーザープロフィール表示
  # ------------------------------------------
  # 【ルート】
  # - GET /mypage（自分）
  # - GET /users/:id（他ユーザー）
  #
  # 【処理の分岐】
  # params[:id] があるかどうかで処理を分ける。
  # - あり: 他ユーザーのプロフィール表示
  # - なし: 自分のマイページ表示
  #
  def show
    if params[:id]
      show_other_user
    else
      show_my_page
    end
  end

  # ------------------------------------------
  # プロフィール編集画面
  # ------------------------------------------
  # 【ルート】GET /edit_profile
  #
  # 【処理内容】
  # 現在ログイン中のユーザー情報を編集フォームに表示。
  # ビュー: app/views/users/edit.html.erb
  #
  def edit
    @user = current_user
  end

  # ------------------------------------------
  # プロフィール更新
  # ------------------------------------------
  # 【ルート】PATCH /mypage
  #
  # 【処理の流れ】
  # 1. フォームから送信されたパラメータを取得
  # 2. ユーザー情報を更新
  # 3. 成功: マイページにリダイレクト
  #    失敗: 編集画面を再表示
  #
  def update
    @user = current_user

    if @user.update(user_params)
      redirect_to mypage_path, notice: "プロフィールを更新しました"
    else
      # 【status: :unprocessable_entity とは？】
      # HTTPステータス422を返す。
      # バリデーションエラー時のRails標準の書き方。
      # Turbo Driveが正しくフォームを処理するために必要。
      render :edit, status: :unprocessable_entity
    end
  end

  private

  # ==========================================
  # プライベートメソッド
  # ==========================================

  # ------------------------------------------
  # 他ユーザーのプロフィール表示
  # ------------------------------------------
  # 【何をするメソッド？】
  # URLに指定されたIDのユーザー情報を表示する。
  # ただし、自分自身の場合はマイページにリダイレクト。
  #
  def show_other_user
    @user = User.find(params[:id])
    @is_own_page = user_signed_in? && @user == current_user

    # 自分自身の場合はマイページにリダイレクト
    # /users/123 でアクセスしても /mypage に統一
    if @is_own_page
      redirect_to mypage_path
      return
    end

    # 他ユーザーの投稿一覧を取得
    load_user_posts(@user)
  end

  # ------------------------------------------
  # 自分のマイページ表示
  # ------------------------------------------
  # 【何をするメソッド？】
  # 自分のタスク管理画面を表示する。
  # 未ログインの場合はログイン画面にリダイレクト。
  #
  def show_my_page
    authenticate_user!  # ログイン必須
    @user = current_user
    @is_own_page = true

    # 各種データを取得
    load_user_posts(@user)     # 投稿一覧
    load_task_data(@user)      # タスク（期限別）
    load_statistics(@user)     # 統計情報
  end

  # ------------------------------------------
  # ユーザーの投稿一覧を取得
  # ------------------------------------------
  # 【何をするメソッド？】
  # 指定ユーザーがアクションプランを作成した動画一覧を取得。
  #
  # 【処理の流れ】
  # 1. ユーザーのPostEntryからpost_idを取得
  # 2. そのpost_idに該当するPostを取得
  # 3. 新しい順にソート
  #
  def load_user_posts(user)
    # ユーザーのアクションプランから動画IDを取得
    user_post_ids = PostEntry.where(user: user).select(:post_id).distinct
    @user_posts = Post.where(id: user_post_ids)
                      .includes(:post_entries)  # N+1クエリ対策
                      .recent
  end

  # ------------------------------------------
  # タスクタブ用データを取得
  # ------------------------------------------
  # 【何をするメソッド？】
  # マイページのタスク管理タブで表示するデータを
  # 期限別に分類して取得する。
  #
  # 【分類】
  # - 今日が期限のタスク
  # - 期限切れのタスク
  # - 今後のタスク（明日以降が期限）
  # - 達成済みタスク
  #
  def load_task_data(user)
    today = Date.current

    # 期限が設定されているアクションプランを取得
    action_entries = PostEntry.where(user: user)
                              .where.not(deadline: nil)
                              .includes(:post)  # N+1クエリ対策

    # 今日が期限のタスク
    @todays_tasks = action_entries.where(achieved_at: nil)
                                  .where(deadline: today)
                                  .order(deadline: :asc)

    # 期限切れのタスク（未達成かつ期限が過去）
    @overdue_tasks = action_entries.where(achieved_at: nil)
                                   .where("post_entries.deadline < ?", today)
                                   .order(deadline: :asc)

    # 今後のタスク（未達成かつ期限が明日以降）
    @upcoming_tasks = action_entries.where(achieved_at: nil)
                                    .where("post_entries.deadline > ?", today)
                                    .order(deadline: :asc)

    # 達成済みタスク（直近20件）
    @completed_tasks = action_entries.where.not(achieved_at: nil)
                                     .order(achieved_at: :desc)
                                     .limit(20)
  end

  # ------------------------------------------
  # 統計情報を取得
  # ------------------------------------------
  # 【何をするメソッド？】
  # マイページに表示する統計データを取得する。
  #
  def load_statistics(user)
    # 総エントリー数
    @total_entries = PostEntry.where(user: user).count

    # 過去30日間の活動データ（GitHub風の草表示用）
    # { Date => count } の形式で取得
    @activity_data = PostEntry.where(user: user)
                              .where("created_at >= ?", 30.days.ago)
                              .group("DATE(created_at)")
                              .count

    # 連続活動日数
    @streak = calculate_streak(user)
  end

  # ------------------------------------------
  # Strong Parameters
  # ------------------------------------------
  # 【何をするメソッド？】
  # フォームから送信されたパラメータのうち、
  # 許可するものを明示的に指定する。
  # セキュリティ対策（マスアサインメント攻撃の防止）。
  #
  # 【許可するパラメータ】
  # - name: 表示名
  # - avatar: プロフィール画像
  # - avatar_cache: CarrierWave用のキャッシュ
  # - favorite_quote: お気に入りの言葉
  # - favorite_quote_url: その言葉が出てくる動画のURL
  #
  def user_params
    params.require(:user).permit(:name, :avatar, :avatar_cache, :favorite_quote, :favorite_quote_url)
  end

  # ------------------------------------------
  # 連続活動日数を計算
  # ------------------------------------------
  # 【何をするメソッド？】
  # 今日または昨日から遡って、連続して活動した日数を計算する。
  # 「連続○日」のような表示に使用。
  #
  # 【ロジック】
  # 1. ユーザーの活動日一覧を取得（降順）
  # 2. 今日から遡ってカウント
  # 3. 連続が途切れたらストップ
  #
  # 【例】
  # 活動日: 1/20, 1/19, 1/18, 1/16（1/17は休み）
  # 今日が1/20の場合 → 連続3日
  #
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

    # 今日活動していなければ、昨日からチェック開始
    # 昨日も活動していなければ連続は0
    unless activity_dates.include?(today)
      check_date = today - 1.day
      return 0 unless activity_dates.include?(check_date)
    end

    # 連続日数をカウント
    activity_dates.each do |date|
      if date == check_date
        streak += 1
        check_date -= 1.day  # 1日前をチェック
      elsif date < check_date
        # 連続が途切れた
        break
      end
    end

    streak
  end
end
