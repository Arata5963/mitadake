# Postsを動画ベース構造に変更
# 「ユーザーの投稿」から「YouTube動画のマスタ」に変更し、複数ユーザー対応

class UpdatePostsForVideoBasedStructure < ActiveRecord::Migration[7.2]
  def change
    # user_idをNULL許可に変更
    change_column_null :posts, :user_id, true

    # 既存のユニーク制約を削除（user_id + youtube_video_id）
    remove_index :posts, [ :user_id, :youtube_video_id ], if_exists: true

    # youtube_video_idのみでユニーク制約を追加
    add_index :posts, :youtube_video_id, unique: true, if_not_exists: true

    # deadline, achieved_atを削除（PostEntryで管理するため）
    remove_column :posts, :deadline, :date
    remove_column :posts, :achieved_at, :datetime
  end
end
