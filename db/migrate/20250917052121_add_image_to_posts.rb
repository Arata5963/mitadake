# Postsテーブルにimageカラム追加
# 投稿に画像を添付できるようにする（後のマイグレーションで削除済み）

class AddImageToPosts < ActiveRecord::Migration[7.2]
  def change
    add_column :posts, :image, :string
  end
end
