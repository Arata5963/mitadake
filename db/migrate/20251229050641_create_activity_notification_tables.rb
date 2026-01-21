# db/migrate/20251229050641_create_activity_notification_tables.rb
# ==========================================
# activity_notificationの通知テーブルを作成
# ==========================================
#
# 【このマイグレーションの目的】
# activity_notification gemで使用する通知関連テーブルを作成する。
# ユーザーへの通知（応援、コメントなど）を管理するための基盤。
#
# 【notifications テーブルのカラム】
# - target: 通知の宛先（polymorphic、通常はUser）
# - notifiable: 通知の対象（polymorphic、Post/Cheer/Commentなど）
# - key: 通知の種類を識別するキー
# - group: 通知のグループ化用（polymorphic）
# - group_owner_id: グループの親通知ID
# - notifier: 通知を発生させたユーザー（polymorphic）
# - parameters: 追加パラメータ（JSON形式）
# - opened_at: 既読日時
#
# 【subscriptions テーブルのカラム】
# - target: 購読者（polymorphic、通常はUser）
# - key: 購読対象の通知種類
# - subscribing: 購読中かどうか
# - subscribing_to_email: メール通知購読中かどうか
# - subscribed_at / unsubscribed_at: 購読・解除日時
#
# ==========================================
# Migration responsible for creating a table with notifications
class CreateActivityNotificationTables < ActiveRecord::Migration[7.2]
  # Create tables
  def change
    create_table :notifications do |t|
      t.belongs_to :target,     polymorphic: true, index: true, null: false
      t.belongs_to :notifiable, polymorphic: true, index: true, null: false
      t.string     :key,                                        null: false
      t.belongs_to :group,      polymorphic: true, index: true
      t.integer    :group_owner_id,                index: true
      t.belongs_to :notifier,   polymorphic: true, index: true
      t.text       :parameters
      t.datetime   :opened_at

      t.timestamps null: false
    end

    create_table :subscriptions do |t|
      t.belongs_to :target,     polymorphic: true, index: true, null: false
      t.string     :key,                           index: true, null: false
      t.boolean    :subscribing,                                null: false, default: true
      t.boolean    :subscribing_to_email,                       null: false, default: true
      t.datetime   :subscribed_at
      t.datetime   :unsubscribed_at
      t.datetime   :subscribed_to_email_at
      t.datetime   :unsubscribed_to_email_at
      t.text       :optional_targets

      t.timestamps null: false
    end
    add_index :subscriptions, [ :target_type, :target_id, :key ], unique: true
  end
end
