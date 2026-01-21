# db/migrate/20251127090318_reset_for_youtube_pivot.rb
# ==========================================
# YouTube特化ピボットのためのデータリセット
# ==========================================
#
# 【このマイグレーションの目的】
# アプリをYouTube学習特化にピボットするにあたり、
# 既存の汎用的な学習データをリセットする。
# ユーザーアカウントは保持し、コンテンツデータのみ削除。
#
# 【削除されるデータ】
# - achievements: 達成記録
# - likes: いいね
# - comments: コメント
# - posts: 投稿
# - user_badges: ユーザーバッジ
#
# 【保持されるデータ】
# - users: ユーザーアカウント（認証情報を保持）
#
# 【注意】
# - この変更は不可逆（削除されたデータは復元不可）
#
# ==========================================
# frozen_string_literal: true

# YouTube特化へのピボットに伴う既存データリセット
class ResetForYoutubePivot < ActiveRecord::Migration[7.2]
  def up
    # 既存データを全削除（破壊的変更）
    # SQLで直接削除（モデル名変更に依存しない）
    execute "DELETE FROM achievements" if table_exists?(:achievements)
    execute "DELETE FROM likes" if table_exists?(:likes)
    execute "DELETE FROM comments" if table_exists?(:comments)
    execute "DELETE FROM posts" if table_exists?(:posts)
    execute "DELETE FROM user_badges" if table_exists?(:user_badges)

    # ユーザーアカウントは残す（認証情報を保持）
  end

  def down
    # データは復元不可
    raise ActiveRecord::IrreversibleMigration, "既存データの削除は取り消せません"
  end
end
