# db/migrate/20260118065030_allow_multiple_entries_per_video_per_user.rb
# ==========================================
# 同一動画に複数エントリーを許可
# ==========================================
#
# 【このマイグレーションの目的】
# user_id + post_id のユニーク制約を削除し、
# 同じユーザーが同じ動画に複数のアクションプランを
# 投稿できるようにする。
#
# 【変更内容】
# - 削除: index_post_entries_on_user_and_post_unique
#
# 【ユースケース】
# - 過去のアクションプランを達成後、新しいアクションプランを追加
# - 1つの動画から複数の学びを得て、それぞれにプランを作成
# - ただし、未達成のアクションプランがある場合は
#   アプリケーション層で制限する
#
# ==========================================
# 同じ動画に複数のアクションプランを投稿できるようにする
# （ただし未達成のアクションプランがない場合のみ）
class AllowMultipleEntriesPerVideoPerUser < ActiveRecord::Migration[7.2]
  def up
    remove_index :post_entries, name: 'index_post_entries_on_user_and_post_unique', if_exists: true
  end

  def down
    add_index :post_entries, [:user_id, :post_id], unique: true, name: 'index_post_entries_on_user_and_post_unique'
  end
end
