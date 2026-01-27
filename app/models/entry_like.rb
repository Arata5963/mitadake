# いいねモデル（アクションプランへの応援）
# ユーザーとアクションプランを繋ぐ中間テーブル

class EntryLike < ApplicationRecord
  belongs_to :user                                           # いいねしたユーザー
  belongs_to :post_entry                                     # いいねされたアクションプラン

  validates :user_id, uniqueness: { scope: :post_entry_id }  # 同じユーザーが同じプランに2回いいね不可
end
