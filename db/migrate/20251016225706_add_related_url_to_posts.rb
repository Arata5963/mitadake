# db/migrate/20251016225706_add_related_url_to_posts.rb
# ==========================================
# Posts テーブルに related_url カラム追加
# ==========================================
#
# 【このマイグレーションの目的】
# 投稿に関連URLを紐付けられるようにする。
# 当初は参考リンクとして設計された。
#
# 【現在の状況】
# 後のマイグレーションで youtube_url にリネームされた。
# YouTube特化に伴い、YouTube動画のURLを保存する用途に変更。
#
# ==========================================

class AddRelatedUrlToPosts < ActiveRecord::Migration[7.2]
  def change
    add_column :posts, :related_url, :string
  end
end
