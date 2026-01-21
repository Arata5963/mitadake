# db/migrate/20250917052121_add_image_to_posts.rb
# ==========================================
# Posts テーブルに image カラム追加
# ==========================================
#
# 【このマイグレーションの目的】
# 投稿に画像を添付できるようにする。
# CarrierWave が画像パスを string として保存する。
#
# 【現在の状況】
# YouTube特化に伴い、このカラムは後のマイグレーションで削除された。
# YouTubeサムネイルを自動取得するため、画像アップロードは不要になった。
#
# ==========================================

class AddImageToPosts < ActiveRecord::Migration[7.2]
  def change
    add_column :posts, :image, :string
  end
end
