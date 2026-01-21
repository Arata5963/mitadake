# app/models/entry_like.rb
# アクションプランへの「いいね」を表す中間テーブル
#
# 関係性:
# - User（いいねしたユーザー） → EntryLike ← PostEntry（いいねされたアクションプラン）
#
# 制約:
# - 同じユーザーが同じアクションプランに複数回いいねできない（ユニーク制約）
class EntryLike < ApplicationRecord
  # ===== アソシエーション =====
  belongs_to :user        # いいねしたユーザー
  belongs_to :post_entry  # いいねされたアクションプラン

  # ===== バリデーション =====
  validates :user_id, uniqueness: { scope: :post_entry_id }
end
