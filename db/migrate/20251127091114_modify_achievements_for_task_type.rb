# frozen_string_literal: true

# db/migrate/20251127091114_modify_achievements_for_task_type.rb
# ==========================================
# Achievements テーブル構造変更（習慣型→タスク型）
# ==========================================
#
# 【このマイグレーションの目的】
# 達成記録の管理方法を変更する。
# 「毎日の習慣記録」から「1回限りのタスク達成」に変更。
#
# 【変更内容】
#   1. インデックス変更: [user_id, post_id, awarded_at] → [user_id, post_id]
#   2. カラムリネーム: awarded_at → achieved_at
#
# 【設計思想の変化】
#   習慣型: 同じ投稿に毎日達成記録をつけられる
#   タスク型: 1つの投稿に対して1回のみ達成可能
#
# 【現在の状況】
# このテーブル自体が後のマイグレーションで削除された。
# 達成管理は post_entries テーブルに統合された。
#
# ==========================================

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
