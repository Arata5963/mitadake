# PostEntriesのユニーク制約を削除
# 同一ユーザーが同一動画に複数のアクションプランを投稿できるようにする

class RemoveUniqueIndexFromPostEntries < ActiveRecord::Migration[7.2]
  def change
    # ユニーク制約を削除（複数アクションプラン投稿を可能にする）
    remove_index :post_entries, name: 'idx_unique_user_post_entry_type'

    # 検索用の通常インデックスを追加
    add_index :post_entries, [ :user_id, :post_id ], name: 'idx_post_entries_user_post'
  end
end
