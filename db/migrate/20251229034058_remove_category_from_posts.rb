# db/migrate/20251229034058_remove_category_from_posts.rb
# ==========================================
# 投稿からカテゴリカラムを削除
# ==========================================
#
# 【このマイグレーションの目的】
# 締め切り駆動型への設計変更に伴い、投稿のカテゴリ分類機能を
# 廃止する。カテゴリはYouTubeチャンネルやタグで代替できるため、
# 冗長なカラムを削除してスキーマを簡素化する。
#
# 【削除されるカラム】
# - category: 投稿のカテゴリ（integer型、enum）
#   - デフォルト値: 6
#   - インデックス付き
#
# ==========================================
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
