# リマインダーをカレンダー形式に変更
# time型からdatetime型に変更してカレンダーUIと連携（既存データは削除される）

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
