class AddThumbnailUrlToPostEntries < ActiveRecord::Migration[7.2]
  def change
    add_column :post_entries, :thumbnail_url, :string
  end
end
