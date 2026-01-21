# db/migrate/20250925044711_remove_icon_from_posts.rb
# ==========================================
# Posts テーブルから icon カラム削除
# ==========================================
#
# 【このマイグレーションの目的】
# 使われていない icon カラムを削除する。
# 設計変更によりアイコン機能は不要になった。
#
# 【remove_column の第3引数】
# データ型（:string）を指定することで、
# ロールバック時にカラムを正しく復元できる。
#
# ==========================================

class RemoveIconFromPosts < ActiveRecord::Migration[7.2]
  def change
    remove_column :posts, :icon, :string
  end
end
