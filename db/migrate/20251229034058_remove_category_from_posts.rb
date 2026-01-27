# Postsテーブルからcategoryカラム削除
# 締め切り駆動型への設計変更に伴い、カテゴリ分類機能を廃止

class RemoveCategoryFromPosts < ActiveRecord::Migration[7.2]
  def up
    remove_index :posts, :category
    remove_column :posts, :category
  end

  def down
    add_column :posts, :category, :integer, default: 6, null: false
    add_index :posts, :category
  end
end
