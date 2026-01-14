# app/models/post_entry.rb
# アクションプラン専用モデル
class PostEntry < ApplicationRecord
  belongs_to :post
  belongs_to :user
  has_many :entry_flames, dependent: :destroy

  # コールバック
  before_validation :set_auto_deadline, on: :create

  # バリデーション
  validates :content, presence: true
  validate :one_incomplete_action_per_user, on: :create

  # スコープ
  scope :recent, -> { order(created_at: :desc) }
  scope :not_achieved, -> { where(achieved_at: nil) }
  scope :achieved, -> { where.not(achieved_at: nil) }
  scope :expired, -> { not_achieved.where("deadline < ?", Date.current) }

  # 達成済みか
  def achieved?
    achieved_at.present?
  end

  # 達成をトグル
  def achieve!
    if achieved?
      update!(achieved_at: nil)
    else
      update!(achieved_at: Time.current)
    end
  end

  # 残り日数を計算（達成済みはnil）
  def days_remaining
    return nil if achieved?
    return nil if deadline.blank?

    (deadline - Date.current).to_i
  end

  # 残り日数の表示用ステータス
  def deadline_status
    days = days_remaining
    return :achieved if achieved?
    return :expired if days.nil? || days < 0

    case days
    when 0 then :today
    when 1 then :urgent
    when 2..3 then :warning
    else :normal
    end
  end

  # 匿名表示かどうか
  def display_anonymous?
    anonymous?
  end

  # 表示用ユーザー名（匿名なら「匿名」を返す）
  def display_user_name
    anonymous? ? "匿名" : user&.name
  end

  # 表示用アバター（匿名ならnilを返す）
  def display_avatar
    anonymous? ? nil : user&.avatar
  end

  # 炎マーク済みかどうか
  def flamed_by?(user)
    return false if user.nil?
    entry_flames.exists?(user_id: user.id)
  end

  private

  # 期限を自動設定（作成日から7日後）
  def set_auto_deadline
    self.deadline ||= Date.current + 7.days
  end

  # ユーザー全体で未達成アクションは1つのみ
  def one_incomplete_action_per_user
    return if user.blank?

    existing = PostEntry.not_achieved.where(user: user).first
    if existing.present?
      errors.add(:base, "未達成のアクションプランがあります。達成してから新しいプランを投稿してください")
    end
  end
end
