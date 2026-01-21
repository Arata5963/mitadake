# db/migrate/20260119100002_remove_anonymous_from_post_entries.rb
# ==========================================
# エントリーからanonymousカラムを削除
# ==========================================
#
# 【このマイグレーションの目的】
# 匿名投稿機能の廃止に伴い、anonymousカラムを削除する。
# すべての投稿はユーザー名を表示する仕様に変更。
#
# 【削除されるカラム】
# - anonymous: 匿名表示フラグ（boolean、デフォルトfalse）
#
# ==========================================
class RemoveAnonymousFromPostEntries < ActiveRecord::Migration[7.2]
  def up
    remove_column :post_entries, :anonymous, :boolean
  end

  def down
    add_column :post_entries, :anonymous, :boolean, default: false, null: false
  end
end
