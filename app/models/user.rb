# app/models/user.rb
# ユーザーを表すモデル
# Devise認証 + Google OAuth2によるソーシャルログインに対応
class User < ApplicationRecord
  # ===== Devise設定 =====
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [ :google_oauth2 ]

  # ===== アソシエーション =====
  has_many :posts, dependent: :destroy
  has_many :entry_likes, dependent: :destroy
  has_many :post_entries, dependent: :destroy

  # ===== ファイルアップロード =====
  mount_uploader :avatar, ImageUploader

  # ===== バリデーション =====
  validates :name, presence: true
  validates :favorite_quote, length: { maximum: 50 }, allow_blank: true
  validates :favorite_quote_url, format: {
    with: %r{\A(https?://)?(www\.)?(youtube\.com/watch\?v=|youtu\.be/)[\w-]+(\?.*)?(?:#.*)?\z},
    message: "は有効なYouTube URLを入力してください"
  }, allow_blank: true
  validate :favorite_quote_consistency

  # ===== クラスメソッド =====

  # 達成数ランキングを取得
  # @param limit [Integer] 取得件数
  # @param period [Symbol] 期間（:all, :today, :week, :month）
  # @return [ActiveRecord::Relation<User>] achieved_count属性付きのユーザー
  def self.by_achieved_count(limit: 10, period: :all)
    scope = User
      .joins(:post_entries)
      .where.not(post_entries: { achieved_at: nil })

    scope = apply_period_filter(scope, period)

    scope
      .group("users.id")
      .order(Arel.sql("COUNT(post_entries.id) DESC"))
      .limit(limit)
      .select("users.*, COUNT(post_entries.id) AS achieved_count")
  end

  # Google OAuth認証からユーザーを取得または作成
  # @param auth [OmniAuth::AuthHash] OmniAuth認証情報
  # @return [User] 既存または新規作成されたユーザー
  def self.from_omniauth(auth)
    # 1) すでに連携済みのユーザーを検索
    user = find_by(provider: auth.provider, uid: auth.uid)
    return user if user

    # 2) 同じメールの既存ユーザーにGoogle情報を連携
    user = find_by(email: auth.info.email)
    if user
      user.update!(provider: auth.provider, uid: auth.uid)
      user.update!(name: auth.info.name) if user.name.blank? && auth.info.name.present?
      return user
    end

    # 3) 新規ユーザーを作成
    create!(
      email:    auth.info.email,
      name:     auth.info.name,
      password: Devise.friendly_token[0, 20],
      provider: auth.provider,
      uid:      auth.uid
    )
  end

  # ===== インスタンスメソッド =====

  # 現在の未達成アクションプランを取得
  # @return [PostEntry, nil] 未達成のアクションプラン（1ユーザー1つのみ）
  def current_action_plan
    post_entries.not_achieved.first
  end

  # 現在取り組んでいる動画を取得
  # @return [Post, nil] 未達成アクションがある動画
  def current_video
    current_action_plan&.post
  end

  private

  # 期間フィルターを適用
  # @param scope [ActiveRecord::Relation] 対象スコープ
  # @param period [Symbol] 期間
  # @return [ActiveRecord::Relation] フィルター適用後のスコープ
  def self.apply_period_filter(scope, period)
    case period.to_sym
    when :today
      scope.where(post_entries: { achieved_at: Time.current.beginning_of_day.. })
    when :week
      scope.where(post_entries: { achieved_at: Time.current.beginning_of_week.. })
    when :month
      scope.where(post_entries: { achieved_at: Time.current.beginning_of_month.. })
    else
      scope
    end
  end

  # すきな言葉と動画URLの整合性チェック
  # 両方入力するか、両方空である必要がある
  def favorite_quote_consistency
    quote_present = favorite_quote.present?
    url_present = favorite_quote_url.present?

    if quote_present != url_present
      errors.add(:base, "すきな言葉と動画URLは両方入力するか、両方空にしてください")
    end
  end
end
