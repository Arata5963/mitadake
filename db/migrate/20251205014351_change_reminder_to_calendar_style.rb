# db/migrate/20251205014351_change_reminder_to_calendar_style.rb
# ==========================================
# リマインダーをカレンダー形式に変更
# ==========================================
#
# 【このマイグレーションの目的】
# リマインダーの時刻指定を time 型から datetime 型に変更する。
# 「毎日○時」形式から「特定の日時」形式に変更することで、
# カレンダーUIとの連携を可能にする。
#
# 【変更内容】
# - remind_time (time型) を削除
# - remind_at (datetime型) を追加
# - remind_at にインデックスを追加（検索高速化）
#
# 【注意】
# - time → datetime 変換不可のため、既存データは全削除される
#
# ==========================================
class ChangeReminderToCalendarStyle < ActiveRecord::Migration[7.2]
  def up
    # 既存リマインダーを全削除（time→datetime変換不可のため）
    execute("DELETE FROM reminders")

    # remind_time (time) を削除
    remove_column :reminders, :remind_time

    # remind_at (datetime) を追加
    add_column :reminders, :remind_at, :datetime, null: false

    # インデックス追加（検索高速化のため）
    add_index :reminders, :remind_at
  end

  def down
    remove_index :reminders, :remind_at
    remove_column :reminders, :remind_at
    add_column :reminders, :remind_time, :time, null: false
  end
end
