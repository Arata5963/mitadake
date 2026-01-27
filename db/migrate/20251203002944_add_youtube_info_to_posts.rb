# PostsテーブルにYouTube情報カラム追加
# YouTube Data APIから取得した動画タイトル・チャンネル名をキャッシュ

class AddYoutubeInfoToPosts < ActiveRecord::Migration[7.2]
  def change
    add_column :posts, :youtube_title, :string
    add_column :posts, :youtube_channel_name, :string
  end
end
