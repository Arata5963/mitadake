class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [ :google_oauth2 ]

  # 通知の受信者として設定（メール通知は無効）
  acts_as_target email: :email, email_allowed: false

  has_many :posts, dependent: :destroy
  has_many :achievements, dependent: :destroy
  has_many :cheers, dependent: :destroy
  has_many :favorite_videos, -> { order(:position) }, dependent: :destroy
  has_many :comment_bookmarks, dependent: :destroy
  has_many :bookmarked_comments, through: :comment_bookmarks, source: :youtube_comment
  has_many :post_entries, dependent: :destroy

  # 達成数ランキング（TOP N ユーザー）
  # period: :all（全期間）, :today（本日）, :week（週間）, :month（月間）
  def self.by_achieved_count(limit: 10, period: :all)
    scope = User
      .joins(:post_entries)
      .where.not(post_entries: { achieved_at: nil })

    # 期間フィルター
    case period.to_sym
    when :today
      scope = scope.where(post_entries: { achieved_at: Time.current.beginning_of_day.. })
    when :week
      scope = scope.where(post_entries: { achieved_at: Time.current.beginning_of_week.. })
    when :month
      scope = scope.where(post_entries: { achieved_at: Time.current.beginning_of_month.. })
    end

    scope
      .group("users.id")
      .order(Arel.sql("COUNT(post_entries.id) DESC"))
      .limit(limit)
      .select("users.*, COUNT(post_entries.id) AS achieved_count")
  end

  mount_uploader :avatar, ImageUploader

  validates :name, presence: true

  # すきな言葉（両方入力 or 両方空）
  validates :favorite_quote, length: { maximum: 50 }, allow_blank: true
  validates :favorite_quote_url, format: {
    with: %r{\A(https?://)?(www\.)?(youtube\.com/watch\?v=|youtu\.be/)[\w-]+(\?.*)?(?:#.*)?\z},
    message: "は有効なYouTube URLを入力してください"
  }, allow_blank: true
  validate :favorite_quote_consistency

  # 既存メールがあればそれにGoogle情報を連携、なければ新規作成
  def self.from_omniauth(auth)
    # 1) すでに連携済みならそのまま返す
    user = find_by(provider: auth.provider, uid: auth.uid)
    return user if user

    # 2) 同じメールの既存ユーザーを連携
    user = find_by(email: auth.info.email)
    if user
      user.update!(provider: auth.provider, uid: auth.uid)
      # 名前が未設定ならGoogleの名前を設定
      user.update!(name: auth.info.name) if user.name.blank? && auth.info.name.present?
      return user
    end

    # 3) なければ新規作成
    create!(
      email:    auth.info.email,
      name:     auth.info.name,
      password: Devise.friendly_token[0, 20],
      provider: auth.provider,
      uid:      auth.uid
    )
  end

  def total_achievements_count
    achievements.count
  end

  private

  # すきな言葉と動画URLは両方入力 or 両方空
  def favorite_quote_consistency
    quote_present = favorite_quote.present?
    url_present = favorite_quote_url.present?

    if quote_present != url_present
      errors.add(:base, "すきな言葉と動画URLは両方入力するか、両方空にしてください")
    end
  end
end
