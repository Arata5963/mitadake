# Achievementsテーブル作成（達成記録）
# ユーザーの達成記録を日ごとに保存（後のマイグレーションで削除済み）

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
