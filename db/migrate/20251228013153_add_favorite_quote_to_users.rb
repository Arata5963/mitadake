# db/migrate/20251228013153_add_favorite_quote_to_users.rb
# ==========================================
# Users テーブルにお気に入り名言カラム追加
# ==========================================
#
# 【このマイグレーションの目的】
# ユーザーのお気に入りの名言をプロフィールに表示する。
# マイページのコレクション機能で使用。
#
# 【カラムの意味】
#   favorite_quote:     名言テキスト（最大50文字）
#   favorite_quote_url: 名言の出典YouTube動画URL
#
# 【表示場所】
#   マイページ → コレクション → Quote Card デザイン
#
# ==========================================

class AddFavoriteQuoteToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :favorite_quote, :string, limit: 50
    add_column :users, :favorite_quote_url, :string
  end
end
