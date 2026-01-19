# app/models/entry_like.rb
class EntryLike < ApplicationRecord
  # ===== アソシエーション =====
  belongs_to :user
  belongs_to :post_entry

  # ===== バリデーション =====
  # 同じユーザーが同じアクションプランに重複していいねできないようにする
  validates :user_id, uniqueness: { scope: :post_entry_id }

end
