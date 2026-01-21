# db/migrate/20260102225706_add_youtube_channel_thumbnail_url_to_posts.rb
# ==========================================
# 投稿にYouTubeチャンネルサムネイルURLを追加
# ==========================================
#
# 【このマイグレーションの目的】
# YouTubeチャンネルのサムネイル画像URLをキャッシュするための
# カラムを追加する。API呼び出しを削減し、表示を高速化する。
#
# 【カラムの意味】
# - youtube_channel_thumbnail_url: チャンネルアイコンの画像URL
#   - YouTube Data APIから取得した値をキャッシュ
#
# ==========================================
class AddYoutubeChannelThumbnailUrlToPosts < ActiveRecord::Migration[7.2]
  def change
    add_column :posts, :youtube_channel_thumbnail_url, :string
  end
end
