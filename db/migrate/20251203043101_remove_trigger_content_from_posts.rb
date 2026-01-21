# db/migrate/20251203043101_remove_trigger_content_from_posts.rb
# ==========================================
# Posts テーブルから trigger_content カラム削除
# ==========================================
#
# 【このマイグレーションの目的】
# 使われなくなった trigger_content カラムを削除する。
# YouTube特化に伴い、「きっかけ」入力欄は不要になった。
#
# 【remove_column の第3引数】
# データ型（:text）を指定することで、
# ロールバック時にカラムを正しく復元できる。
#
# ==========================================

class RemoveTriggerContentFromPosts < ActiveRecord::Migration[7.2]
  def change
    remove_column :posts, :trigger_content, :text
  end
end
