# db/migrate/20260119100003_rename_entry_flames_to_entry_likes.rb
class RenameEntryFlamesToEntryLikes < ActiveRecord::Migration[7.2]
  def change
    rename_table :entry_flames, :entry_likes
  end
end
