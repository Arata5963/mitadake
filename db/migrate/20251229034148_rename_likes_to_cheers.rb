# db/migrate/20251229034148_rename_likes_to_cheers.rb
# ==========================================
# likesテーブルをcheersにリネーム
# ==========================================
#
# 【このマイグレーションの目的】
# 「いいね」機能を「応援」機能にリブランディングするため、
# likesテーブルをcheersテーブルにリネームする。
# アクションプランを実行する人を応援するというコンセプトに合わせた変更。
#
# 【テーブル名の変更】
# - 変更前: likes
# - 変更後: cheers
#
# ==========================================
class RenameLikesToCheers < ActiveRecord::Migration[7.2]
  def change
    rename_table :likes, :cheers
  end
end
