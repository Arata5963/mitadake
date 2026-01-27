# PostEntriesテーブルからanonymousカラム削除
# 匿名投稿機能の廃止に伴い、匿名表示フラグを削除

class RemoveAnonymousFromPostEntries < ActiveRecord::Migration[7.2]
  def up
    remove_column :post_entries, :anonymous, :boolean
  end

  def down
    add_column :post_entries, :anonymous, :boolean, default: false, null: false
  end
end
