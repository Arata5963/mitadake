# db/migrate/20260104010805_update_posts_for_video_based_structure.rb
# ==========================================
# 投稿を動画ベース構造に変更
# ==========================================
#
# 【このマイグレーションの目的】
# postsを「ユーザーの投稿」から「YouTube動画のマスタ」に変更する。
# これにより、1つの動画に複数ユーザーがエントリーを追加できる
# 構造になる。
#
# 【変更内容】
# - user_id: NOT NULL制約を削除（動画マスタは特定ユーザーに紐付かない）
# - ユニーク制約: user_id + youtube_video_id → youtube_video_idのみ
# - deadline, achieved_at: 削除（PostEntryで管理するため）
#
# 【アーキテクチャの変更】
# - 変更前: posts = ユーザーの投稿（user必須）
# - 変更後: posts = 動画マスタ（user任意、video_idでユニーク）
#
# ==========================================
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
