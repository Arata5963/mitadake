# CommentBookmarksテーブル作成（コメントブックマーク）
# ユーザーが有益なYouTubeコメントをブックマークできる機能

class CreateCommentBookmarks < ActiveRecord::Migration[7.2]
  def change
    create_table :comment_bookmarks do |t|
      t.references :user, null: false, foreign_key: true
      t.references :youtube_comment, null: false, foreign_key: true

      t.timestamps
    end

    add_index :comment_bookmarks, [ :user_id, :youtube_comment_id ], unique: true
  end
end
