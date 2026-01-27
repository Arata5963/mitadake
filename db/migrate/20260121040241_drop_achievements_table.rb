# Achievementsテーブル削除
# post_entriesに機能統合済みのため削除

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
    add_index :achievements, [ :user_id, :post_id ], unique: true, name: "idx_unique_achievements"
  end
end
