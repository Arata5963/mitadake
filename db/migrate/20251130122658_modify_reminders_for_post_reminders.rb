# db/migrate/20251130122658_modify_reminders_for_post_reminders.rb
# ==========================================
# remindersテーブルを投稿リマインダー用に変更
# ==========================================
#
# 【このマイグレーションの目的】
# ユーザー単位の汎用リマインダーから、投稿に紐づくリマインダーに
# テーブル構造を変更する。特定のアクションプランに対して
# リマインドを設定できるようにする。
#
# 【変更内容】
# - enabled カラムを削除
# - time を remind_time にリネーム
# - post_id を追加（NOT NULL、外部キー）
# - user_id + post_id のユニーク制約を追加
#
# 【注意】
# - 既存のリマインダーデータは全削除される
#
# ==========================================
class ModifyRemindersForPostReminders < ActiveRecord::Migration[7.2]
  def change
    # 既存データを削除（要件通り）
    execute("DELETE FROM reminders") if table_exists?(:reminders)

    # 既存カラムを削除
    remove_column :reminders, :enabled, :boolean if column_exists?(:reminders, :enabled)

    # timeカラムをremind_timeにリネーム
    rename_column :reminders, :time, :remind_time

    # post_idカラムを追加（NOT NULL、外部キー）
    add_reference :reminders, :post, null: false, foreign_key: true

    # user_id + post_idのユニーク制約を追加
    add_index :reminders, %i[user_id post_id], unique: true, name: "idx_unique_user_post_reminder"
  end
end
