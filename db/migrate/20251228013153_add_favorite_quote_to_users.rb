# Usersテーブルにお気に入り名言カラム追加
# マイページのコレクション機能で使用する名言テキストと出典URLを保存

class AddFavoriteQuoteToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :favorite_quote, :string, limit: 50
    add_column :users, :favorite_quote_url, :string
  end
end
