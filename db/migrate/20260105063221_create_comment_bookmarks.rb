# db/migrate/20260105063221_create_comment_bookmarks.rb
# ==========================================
# コメントブックマークテーブルを作成
# ==========================================
#
# 【このマイグレーションの目的】
# ユーザーが有益なYouTubeコメントをブックマークできる
# 機能のためのテーブルを作成する。
#
# 【カラムの意味】
# - user_id: ブックマークしたユーザーへの外部キー
# - youtube_comment_id: ブックマークしたコメントへの外部キー
#
# 【インデックス】
# - user_id + youtube_comment_id: 同じコメントの重複ブックマーク防止
#
# ==========================================
class CreateCommentBookmarks < ActiveRecord::Migration[7.2]
  def change
    create_table :comment_bookmarks do |t|
      t.references :user, null: false, foreign_key: true
      t.references :youtube_comment, null: false, foreign_key: true

      t.timestamps
    end

    add_index :comment_bookmarks, [:user_id, :youtube_comment_id], unique: true
  end
end
