# app/models/entry_flame.rb
class EntryFlame < ApplicationRecord
  # ===== アソシエーション =====
  belongs_to :user
  belongs_to :post_entry

  # ===== バリデーション =====
  # 同じユーザーが同じアクションプランに重複して炎を付けられないようにする
  validates :user_id, uniqueness: { scope: :post_entry_id }

end
