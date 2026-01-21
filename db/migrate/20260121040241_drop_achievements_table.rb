# db/migrate/20260121040241_drop_achievements_table.rb
# ==========================================
# Achievements テーブル削除
# ==========================================
#
# 【このマイグレーションの目的】
# 使われなくなった achievements テーブルを削除する。
# アクションプラン機能は post_entries テーブルに統合済み。
#
# 【up/down メソッド】
#   up:   マイグレーション実行時（テーブル削除）
#   down: ロールバック時（テーブル再作成）
#
# 【changeメソッドとの違い】
#   change: Railsが自動でロールバック方法を推測
#   up/down: 明示的にロールバック方法を定義
#   drop_table は自動推測できないため up/down を使用
#
# ==========================================

class DropAchievementsTable < ActiveRecord::Migration[7.2]
  def up
    drop_table :achievements
  end

  def down
    create_table :achievements do |t|
      t.bigint :user_id, null: false
      t.bigint :post_id, null: false
      t.date :achieved_at, null: false, default: -> { "CURRENT_DATE" }
      t.timestamps
    end

    add_index :achievements, :post_id
    add_index :achievements, :user_id
    add_index :achievements, [:user_id, :post_id], unique: true, name: "idx_unique_achievements"
  end
end
