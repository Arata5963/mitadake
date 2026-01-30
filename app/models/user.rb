# ユーザーモデル
# メールアドレス/パスワードまたはGoogleアカウントでログインする人の情報を管理

class User < ApplicationRecord
  devise :database_authenticatable, :registerable,                                   # DB認証、登録機能
         :recoverable, :rememberable, :validatable,                                  # パスワードリセット、ログイン保持、バリデーション
         :omniauthable, omniauth_providers: [ :google_oauth2 ]                       # Googleログイン対応

  has_many :posts, dependent: :destroy                                               # 投稿した動画一覧
  has_many :entry_likes, dependent: :destroy                                         # 押したいいね一覧
  has_many :post_entries, dependent: :destroy                                        # 作成したアクションプラン一覧

  mount_uploader :avatar, ImageUploader                                              # プロフィール画像アップローダー

  validates :name, presence: true                                                    # 名前は必須
  validates :favorite_quote_url, format: {                                           # お気に入り動画URLの形式チェック
    with: %r{\A(https?://)?(www\.)?(youtube\.com/watch\?v=|youtu\.be/)[\w-]+(\?.*)?(?:#.*)?\z},  # YouTube URLの正規表現
    message: "は有効なYouTube URLを入力してください"                                  # エラーメッセージ
  }, allow_blank: true                                                               # 空でもOK

  # 達成数ランキングを取得
  def self.by_achieved_count(limit: 10, period: :all)
    scope = User                                                                     # ベースのスコープ
      .joins(:post_entries)                                                          # post_entriesテーブルと結合
      .where.not(post_entries: { achieved_at: nil })                                 # 達成済みのみ

    scope = apply_period_filter(scope, period)                                       # 期間フィルター適用

    scope
      .group("users.id")                                                             # ユーザーごとにまとめる
      .order(Arel.sql("COUNT(post_entries.id) DESC"))                                # 件数が多い順
      .limit(limit)                                                                  # 指定件数まで
      .select("users.*, COUNT(post_entries.id) AS achieved_count")                   # 件数も取得
  end

  # Googleログイン処理
  def self.from_omniauth(auth)
    user = find_by(provider: auth.provider, uid: auth.uid)                           # Google連携済みユーザーを探す
    return user if user                                                              # 見つかればそれを返す

    user = find_by(email: auth.info.email)                                           # 同じメールの既存ユーザーを探す
    if user                                                                          # 見つかった場合
      user.update!(provider: auth.provider, uid: auth.uid)                           # Google情報を追加
      user.update!(name: auth.info.name) if user.name.blank? && auth.info.name.present?  # 名前が空ならセット
      return user                                                                    # ユーザーを返す
    end

    create!(                                                                         # 新規ユーザーを作成
      email:    auth.info.email,                                                     # メールアドレス
      name:     auth.info.name,                                                      # 名前
      password: Devise.friendly_token[0, 20],                                        # ランダムなパスワード
      provider: auth.provider,                                                       # プロバイダ名
      uid:      auth.uid                                                             # プロバイダでのユーザーID
    )
  end

  # 現在取り組み中のアクションプランを取得（最初の1件）
  def current_action_plan
    post_entries.not_achieved.first                                                  # 未達成プランの最初の1件
  end

  # 現在取り組み中の動画を取得（最初の1件）
  def current_video
    current_action_plan&.post                                                        # アクションプランの元動画
  end

  private

  # 期間フィルターを適用
  def self.apply_period_filter(scope, period)
    case period.to_sym                                                               # 期間で分岐
    when :today                                                                      # 今日
      scope.where(post_entries: { achieved_at: Time.current.beginning_of_day.. })    # 今日の0時以降
    when :week                                                                       # 今週
      scope.where(post_entries: { achieved_at: Time.current.beginning_of_week.. })   # 今週の月曜0時以降
    when :month                                                                      # 今月
      scope.where(post_entries: { achieved_at: Time.current.beginning_of_month.. })  # 今月の1日0時以降
    else                                                                             # :allの場合
      scope                                                                          # フィルターなし
    end
  end

end
