# db/migrate/20251203002944_add_youtube_info_to_posts.rb
# ==========================================
# Posts テーブルに YouTube情報カラム追加
# ==========================================
#
# 【このマイグレーションの目的】
# YouTube動画のメタ情報を保存できるようにする。
# YouTube Data API から取得した情報をキャッシュ。
#
# 【カラムの意味】
#   youtube_title:        動画タイトル
#   youtube_channel_name: チャンネル名
#
# 【なぜキャッシュするのか？】
#   - API呼び出し回数を削減（APIには制限がある）
#   - 表示速度の向上
#   - オフライン時も情報を表示可能
#
# ==========================================

class AddYoutubeInfoToPosts < ActiveRecord::Migration[7.2]
  def change
    add_column :posts, :youtube_title, :string
    add_column :posts, :youtube_channel_name, :string
  end
end
