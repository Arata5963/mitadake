class AddReflectionAndResultImageToPostEntries < ActiveRecord::Migration[7.2]
  def change
    add_column :post_entries, :reflection, :text
    add_column :post_entries, :result_image, :string
  end
end
