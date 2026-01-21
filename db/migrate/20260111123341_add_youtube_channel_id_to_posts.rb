# db/migrate/20260111123341_add_youtube_channel_id_to_posts.rb
# ==========================================
# 投稿にYouTubeチャンネルIDカラムを追加
# ==========================================
#
# 【このマイグレーションの目的】
# YouTubeチャンネルのIDを保存するカラムを追加する。
# チャンネル別の動画一覧表示や、チャンネル情報の
# 取得・更新に使用される。
#
# 【カラムの意味】
# - youtube_channel_id: YouTubeチャンネルの一意識別子
#   - 例: UCxxxxxxxxxxxxxx
#   - YouTube Data APIでチャンネル情報を取得する際に使用
#
# ==========================================
class AddYoutubeChannelIdToPosts < ActiveRecord::Migration[7.2]
  def change
    add_column :posts, :youtube_channel_id, :string
  end
end
