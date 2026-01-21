# db/migrate/20251229034228_drop_reminders.rb
# ==========================================
# remindersテーブルを削除
# ==========================================
#
# 【このマイグレーションの目的】
# リマインダー機能の廃止に伴い、remindersテーブルを削除する。
# 締め切り駆動型への設計変更により、独立したリマインダーテーブルは
# 不要となった。
#
# 【削除されるテーブル構造】
# - reminders:
#   - user_id: ユーザーへの外部キー
#   - post_id: 投稿への外部キー
#   - remind_at: リマインド日時
#   - idx_unique_user_post_reminder: user_id + post_idのユニーク制約
#
# ==========================================
class DropReminders < ActiveRecord::Migration[7.2]
  def up
    drop_table :reminders
  end

  def down
    create_table :reminders do |t|
      t.references :user, null: false, foreign_key: true
      t.references :post, null: false, foreign_key: true
      t.datetime :remind_at, null: false

      t.timestamps
    end

    add_index :reminders, :remind_at
    add_index :reminders, %i[user_id post_id], unique: true, name: "idx_unique_user_post_reminder"
  end
end
