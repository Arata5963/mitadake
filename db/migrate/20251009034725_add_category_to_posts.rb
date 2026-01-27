# Postsテーブルにcategoryカラム追加
# 投稿をカテゴリ分けできるようにする（後のマイグレーションで削除済み）

class AddCategoryToPosts < ActiveRecord::Migration[7.2]
  def change
    add_column :posts, :category, :integer, default: 6, null: false
    add_index :posts, :category
  end
end
