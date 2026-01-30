class RemoveFavoriteQuoteFromUsers < ActiveRecord::Migration[7.2]
  def change
    remove_column :users, :favorite_quote, :string
  end
end
