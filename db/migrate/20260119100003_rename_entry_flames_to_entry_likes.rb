# db/migrate/20260119100003_rename_entry_flames_to_entry_likes.rb
# ==========================================
# entry_flamesテーブルをentry_likesにリネーム
# ==========================================
#
# 【このマイグレーションの目的】
# 「炎」から「いいね」への呼称変更に伴い、
# テーブル名をentry_flamesからentry_likesに変更する。
# より一般的で分かりやすい名称に統一する。
#
# 【テーブル名の変更】
# - 変更前: entry_flames
# - 変更後: entry_likes
#
# ==========================================
class RenameEntryFlamesToEntryLikes < ActiveRecord::Migration[7.2]
  def change
    rename_table :entry_flames, :entry_likes
  end
end
