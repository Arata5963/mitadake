# YouTube特化ピボットのためのデータリセット
# ユーザー以外のコンテンツデータを全削除（不可逆）

# frozen_string_literal: true

class ResetForYoutubePivot < ActiveRecord::Migration[7.2]
  def up
    execute "DELETE FROM achievements" if table_exists?(:achievements)
    execute "DELETE FROM likes" if table_exists?(:likes)
    execute "DELETE FROM comments" if table_exists?(:comments)
    execute "DELETE FROM posts" if table_exists?(:posts)
    execute "DELETE FROM user_badges" if table_exists?(:user_badges)
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "既存データの削除は取り消せません"
  end
end
