# db/migrate/20260119100002_remove_anonymous_from_post_entries.rb
class RemoveAnonymousFromPostEntries < ActiveRecord::Migration[7.2]
  def up
    remove_column :post_entries, :anonymous, :boolean
  end

  def down
    add_column :post_entries, :anonymous, :boolean, default: false, null: false
  end
end
