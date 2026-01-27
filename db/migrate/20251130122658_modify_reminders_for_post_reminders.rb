# remindersテーブルを投稿リマインダー用に変更
# ユーザー単位から投稿に紐づくリマインダーに構造変更（既存データは削除される）

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
