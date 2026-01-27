# UserBadgesテーブル作成（バッジ・称号）
# ユーザーが獲得したバッジを管理する（後のマイグレーションで削除済み）

class CreateUserBadges < ActiveRecord::Migration[7.2]
  def change
    create_table :user_badges do |t|
      t.references :user, null: false, foreign_key: true
      t.string :badge_key, null: false
      t.datetime :awarded_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.timestamps
    end

    # 同じバッジは1回のみ獲得可能
    add_index :user_badges, [ :user_id, :badge_key ], unique: true
  end
end
