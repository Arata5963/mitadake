# PostEntriesテーブルにuser_idとanonymousカラム追加
# エントリーを投稿したユーザーを直接参照し、匿名投稿も可能にする

class AddUserIdAndAnonymousToPostEntries < ActiveRecord::Migration[7.2]
  def change
    add_reference :post_entries, :user, null: true, foreign_key: true
    add_column :post_entries, :anonymous, :boolean, default: false, null: false
    add_index :post_entries, [ :user_id, :post_id, :entry_type ],
              unique: true, name: 'idx_unique_user_post_entry_type'
  end
end
