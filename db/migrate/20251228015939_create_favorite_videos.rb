# db/migrate/20251228015939_create_favorite_videos.rb
# ==========================================
# お気に入り動画テーブルを作成
# ==========================================
#
# 【このマイグレーションの目的】
# ユーザーがお気に入りのYouTube動画を保存できる機能のための
# テーブルを作成する。プロフィールページでお気に入り動画を
# 表示するために使用される。
#
# 【カラムの意味】
# - user_id: ユーザーへの外部キー
# - youtube_url: YouTube動画のURL（必須）
# - youtube_title: 動画のタイトル（キャッシュ用）
# - youtube_channel_name: チャンネル名（キャッシュ用）
# - position: 表示順序（ユーザーごとにユニーク）
#
# 【インデックス】
# - user_id + position: ユーザーごとの表示順序を一意に保つ
#
# ==========================================
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
