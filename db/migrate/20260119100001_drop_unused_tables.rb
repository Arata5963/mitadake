# db/migrate/20260119100001_drop_unused_tables.rb
# ==========================================
# 未使用テーブルを削除
# ==========================================
#
# 【このマイグレーションの目的】
# 機能の整理・廃止に伴い、使用されなくなったテーブルを削除する。
# データベーススキーマを簡素化し、メンテナンス性を向上させる。
#
# 【削除されるテーブル】
# - cheers: 投稿への応援（entry_likesに機能移行）
# - favorite_videos: お気に入り動画（機能廃止）
# - comment_bookmarks: コメントブックマーク（機能廃止）
# - youtube_comments: YouTubeコメントキャッシュ（機能廃止）
#
# ==========================================
class DropUnusedTables < ActiveRecord::Migration[7.2]
  def up
    drop_table :cheers, if_exists: true
    drop_table :favorite_videos, if_exists: true
    drop_table :comment_bookmarks, if_exists: true
    drop_table :youtube_comments, if_exists: true
  end

  def down
    create_table :cheers do |t|
      t.references :user, null: false, foreign_key: true
      t.references :post, null: false, foreign_key: true
      t.timestamps
    end
    add_index :cheers, [:user_id, :post_id], unique: true

    create_table :favorite_videos do |t|
      t.references :user, null: false, foreign_key: true
      t.string :youtube_video_id, null: false
      t.string :youtube_title
      t.string :youtube_channel_name
      t.integer :position
      t.timestamps
    end

    create_table :comment_bookmarks do |t|
      t.references :user, null: false, foreign_key: true
      t.references :youtube_comment, null: false, foreign_key: true
      t.timestamps
    end
    add_index :comment_bookmarks, [:user_id, :youtube_comment_id], unique: true

    create_table :youtube_comments do |t|
      t.references :post, null: false, foreign_key: true
      t.text :content
      t.string :author_name
      t.string :author_channel_id
      t.integer :like_count, default: 0
      t.string :category
      t.datetime :published_at
      t.timestamps
    end
  end
end
