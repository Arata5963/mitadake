# db/migrate/20260118010133_add_thumbnail_url_to_post_entries.rb
# ==========================================
# エントリーにサムネイルURLカラムを追加
# ==========================================
#
# 【このマイグレーションの目的】
# エントリーカードにカスタムサムネイル画像を設定できるように、
# thumbnail_urlカラムを追加する。
#
# 【カラムの意味】
# - thumbnail_url: エントリーのサムネイル画像URL
#   - 設定されていない場合は動画のサムネイルを使用
#   - ユーザーがカスタム画像を設定可能
#
# ==========================================
class AddThumbnailUrlToPostEntries < ActiveRecord::Migration[7.2]
  def change
    add_column :post_entries, :thumbnail_url, :string
  end
end
