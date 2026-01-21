# db/migrate/20250914112333_create_achievements.rb
# ==========================================
# Achievements テーブル作成（達成記録）
# ==========================================
#
# 【このテーブルの役割】
# ユーザーの達成記録を日ごとに保存する。
# 1ユーザー × 1投稿 × 1日 = 1レコード
#
# 【現在の状況】
# このテーブルは後のマイグレーションで削除された。
# アクションプラン機能は post_entries テーブルに統合された。
#
# ==========================================

class CreateAchievements < ActiveRecord::Migration[7.2]
  def change
    create_table :achievements do |t|
      t.references :user, null: false, foreign_key: true
      t.references :post, null: false, foreign_key: true
      t.date :awarded_at, null: false, default: -> { "CURRENT_DATE" }
      t.timestamps
    end

    # 1ユーザー×1投稿×1日 = 1レコードの一意制約
    add_index :achievements, [ :user_id, :post_id, :awarded_at ],
              unique: true, name: "idx_unique_daily_achievements"
  end
end
