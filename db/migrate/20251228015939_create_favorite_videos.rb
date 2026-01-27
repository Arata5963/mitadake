# FavoriteVideosテーブル作成（お気に入り動画）
# ユーザーがお気に入りのYouTube動画を保存し、プロフィールに表示する

class CreateFavoriteVideos < ActiveRecord::Migration[7.2]
  def change
    create_table :favorite_videos do |t|
      t.references :user, null: false, foreign_key: true
      t.string :youtube_url, null: false
      t.string :youtube_title
      t.string :youtube_channel_name
      t.integer :position, null: false

      t.timestamps
    end

    add_index :favorite_videos, [ :user_id, :position ], unique: true
  end
end
