# Postsテーブルにiconカラム追加
# 投稿にアイコンを設定できるようにする（すぐ後のマイグレーションで削除済み）

class AddIconToPosts < ActiveRecord::Migration[7.2]
  def change
    add_column :posts, :icon, :string
  end
end
