# db/migrate/20260105063115_create_youtube_comments.rb
# ==========================================
# YouTubeコメントテーブルを作成
# ==========================================
#
# 【このマイグレーションの目的】
# YouTube動画のコメントをキャッシュするテーブルを作成する。
# コメントをカテゴリ分類し、有益なコメントを
# ハイライト表示する機能に使用される。
#
# 【カラムの意味】
# - post_id: 対象の投稿（動画）への外部キー
# - youtube_comment_id: YouTubeコメントの一意ID
# - author_name: コメント投稿者名
# - author_image_url: 投稿者のプロフィール画像URL
# - author_channel_url: 投稿者のチャンネルURL
# - content: コメント本文
# - like_count: いいね数
# - category: AIによるカテゴリ分類（質問、感想、補足情報など）
# - youtube_published_at: YouTube上での投稿日時
#
# 【インデックス】
# - youtube_comment_id: 重複防止
# - category: カテゴリ別表示用
# - post_id + category: 動画別カテゴリ表示用
#
# ==========================================
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
