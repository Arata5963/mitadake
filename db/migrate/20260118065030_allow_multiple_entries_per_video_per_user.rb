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
