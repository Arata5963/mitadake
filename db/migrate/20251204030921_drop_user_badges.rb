# UserBadgesテーブル削除
# バッジ機能の実装優先度が下がり、使われなくなったテーブルを削除

class DropUserBadges < ActiveRecord::Migration[7.2]
  def up
    drop_table :user_badges
  end

  def down
    create_table :user_badges do |t|
      t.references :user, null: false, foreign_key: true
      t.string :badge_key, null: false
      t.datetime :awarded_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.timestamps
    end

    add_index :user_badges, [ :user_id, :badge_key ], unique: true
  end
end
