# db/migrate/20260102231030_add_blog_fields_to_post_entries.rb
# ==========================================
# エントリーにブログ用フィールドを追加
# ==========================================
#
# 【このマイグレーションの目的】
# エントリーをブログ記事のように公開できる機能のため、
# タイトルと公開日時のカラムを追加する。
#
# 【カラムの意味】
# - title: エントリーのタイトル（ブログ記事として公開時に使用）
# - published_at: 公開日時（NULL = 非公開、日時設定 = 公開済み）
#
# ==========================================
class AddBlogFieldsToPostEntries < ActiveRecord::Migration[7.2]
  def change
    add_column :post_entries, :title, :string
    add_column :post_entries, :published_at, :datetime
  end
end
