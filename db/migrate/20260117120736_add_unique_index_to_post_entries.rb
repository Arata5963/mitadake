# PostEntriesにユニークインデックスを追加
# 同一ユーザーが同一動画に複数エントリーを持つことを防ぐ（重複は削除）

class AddUniqueIndexToPostEntries < ActiveRecord::Migration[7.2]
  def up
    # 削除対象のpost_entry_idsを特定
    duplicate_ids = execute(<<-SQL).map { |row| row['id'] }
      SELECT id FROM post_entries
      WHERE id NOT IN (
        SELECT MAX(id)
        FROM post_entries
        GROUP BY user_id, post_id
      )
    SQL

    if duplicate_ids.any?
      # 関連するentry_flamesを先に削除
      execute("DELETE FROM entry_flames WHERE post_entry_id IN (#{duplicate_ids.join(',')})")

      # 重複post_entriesを削除
      execute("DELETE FROM post_entries WHERE id IN (#{duplicate_ids.join(',')})")
    end

    # ユニークインデックスを追加
    add_index :post_entries, [ :user_id, :post_id ], unique: true, name: 'index_post_entries_on_user_and_post_unique'
  end

  def down
    remove_index :post_entries, name: 'index_post_entries_on_user_and_post_unique'
  end
end
