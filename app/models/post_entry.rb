# app/models/post_entry.rb
# アクションプラン専用モデル
class PostEntry < ApplicationRecord
  belongs_to :post
  belongs_to :user

  # バリデーション
  validates :content, presence: true
  validates :deadline, presence: true

  # スコープ
  scope :recent, -> { order(created_at: :desc) }
  scope :not_achieved, -> { where(achieved_at: nil) }
  scope :achieved, -> { where.not(achieved_at: nil) }

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
end
