# remindersテーブル削除
# 締め切り駆動型への設計変更により、リマインダー機能を廃止

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
