# db/migrate/20260102041731_add_youtube_video_id_to_posts.rb
# ==========================================
# 投稿にYouTube動画IDカラムを追加
# ==========================================
#
# 【このマイグレーションの目的】
# postsテーブルにyoutube_video_idカラムを追加する。
# URLから抽出した動画IDを保存し、動画の重複チェックや
# 検索を効率化する。
#
# 【カラムの意味】
# - youtube_video_id: YouTube動画の一意識別子（11文字の英数字）
#   - youtube_urlから抽出して保存
#   - ユニーク制約は後続のマイグレーション（MigratePostsToEntries）で追加
#
# ==========================================
class AddYoutubeVideoIdToPosts < ActiveRecord::Migration[7.2]
  def change
    add_column :posts, :youtube_video_id, :string
    # ユニーク制約はデータ移行後に追加（MigratePostsToEntriesで追加）
  end
end
