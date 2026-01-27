# Postsテーブルからiconカラム削除
# 使われていないiconカラムを削除する（設計変更でアイコン機能は不要になった）

class RemoveIconFromPosts < ActiveRecord::Migration[7.2]
  def change
    remove_column :posts, :icon, :string
  end
end
