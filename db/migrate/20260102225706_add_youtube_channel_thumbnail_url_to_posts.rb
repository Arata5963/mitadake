# Postsテーブルにyoutube_channel_thumbnail_urlカラム追加
# YouTubeチャンネルのサムネイル画像URLをキャッシュしてAPI呼び出しを削減

class AddYoutubeChannelThumbnailUrlToPosts < ActiveRecord::Migration[7.2]
  def change
    add_column :posts, :youtube_channel_thumbnail_url, :string
  end
end
