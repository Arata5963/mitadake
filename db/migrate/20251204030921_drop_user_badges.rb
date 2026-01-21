# db/migrate/20251204030921_drop_user_badges.rb
# ==========================================
# UserBadges テーブル削除
# ==========================================
#
# 【このマイグレーションの目的】
# 使われなくなった user_badges テーブルを削除する。
# バッジ機能は実装優先度が下がり、一時的に保留となった。
#
# 【up/down メソッド】
#   up:   マイグレーション実行時（テーブル削除）
#   down: ロールバック時（テーブル再作成）
#
# ==========================================

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
