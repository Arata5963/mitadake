# Postsテーブルにyoutube_channel_idカラム追加
# チャンネル別の動画一覧表示やチャンネル情報取得に使用

class AddYoutubeChannelIdToPosts < ActiveRecord::Migration[7.2]
  def change
    add_column :posts, :youtube_channel_id, :string
  end
end
