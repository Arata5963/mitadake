# Postsテーブルにyoutube_video_idカラム追加
# URLから抽出した動画IDを保存し、重複チェックや検索を効率化

class AddYoutubeVideoIdToPosts < ActiveRecord::Migration[7.2]
  def change
    add_column :posts, :youtube_video_id, :string
    # ユニーク制約はデータ移行後に追加（MigratePostsToEntriesで追加）
  end
end
