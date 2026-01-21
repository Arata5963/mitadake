# db/migrate/20251009034725_add_category_to_posts.rb
# ==========================================
# Posts テーブルに category カラム追加
# ==========================================
#
# 【このマイグレーションの目的】
# 投稿をカテゴリ分けできるようにする。
# integer 型で enum として管理する想定。
#
# 【カラムの意味】
#   category: カテゴリID（0=仕事, 1=学習, ... 6=その他）
#   デフォルト値 6 は「その他」を想定
#
# 【現在の状況】
# このカラムは後のマイグレーションで削除された。
# YouTube特化に伴い、カテゴリ分けは不要になった。
#
# ==========================================

class AddCategoryToPosts < ActiveRecord::Migration[7.2]
  def change
    add_column :posts, :category, :integer, default: 6, null: false
    add_index :posts, :category
  end
end
