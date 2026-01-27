# YoutubeCommentsテーブル作成（YouTubeコメントキャッシュ）
# YouTube動画のコメントをキャッシュし、カテゴリ分類してハイライト表示

class CreateYoutubeComments < ActiveRecord::Migration[7.2]
  def change
    create_table :youtube_comments do |t|
      t.references :post, null: false, foreign_key: true
      t.string :youtube_comment_id, null: false
      t.string :author_name
      t.string :author_image_url
      t.string :author_channel_url
      t.text :content
      t.integer :like_count, default: 0
      t.string :category
      t.datetime :youtube_published_at

      t.timestamps
    end

    add_index :youtube_comments, :youtube_comment_id, unique: true
    add_index :youtube_comments, :category
    add_index :youtube_comments, [ :post_id, :category ]
  end
end
