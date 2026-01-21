class Achievement < ApplicationRecord
  belongs_to :user
  belongs_to :post

  # タスク型：1投稿につき1ユーザー1回のみ達成可能
  validates :achieved_at, presence: true
  validates :post_id, uniqueness: {
    scope: :user_id,
    message: "既に達成済みです"
  }

end
