# frozen_string_literal: true

# Achievementsテーブル構造変更（習慣型からタスク型へ）
# 毎日の習慣記録から1回限りのタスク達成に変更（テーブル自体は後に削除）

class ModifyAchievementsForTaskType < ActiveRecord::Migration[7.2]
  def change
    # 旧インデックス削除（user_id + post_id + awarded_at のユニーク制約）
    remove_index :achievements, name: "idx_unique_daily_achievements"

    # 新インデックス追加（user_id + post_id のみのユニーク制約）
    # 1つの投稿に対して1人のユーザーは1回のみ達成可能
    add_index :achievements, [ :user_id, :post_id ], unique: true, name: "idx_unique_achievements"

    # awarded_at カラムを achieved_at にリネーム（意味的な明確化）
    rename_column :achievements, :awarded_at, :achieved_at
  end
end
