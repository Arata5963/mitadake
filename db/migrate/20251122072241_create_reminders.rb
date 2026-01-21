# db/migrate/20251122072241_create_reminders.rb
# ==========================================
# Reminders テーブル作成（リマインダー機能）
# ==========================================
#
# 【このテーブルの役割】
# ユーザーへのリマインダー通知設定を管理する。
# 毎日決まった時間に通知を送る機能。
#
# 【カラムの意味】
#   user_id: リマインダーを設定したユーザー
#   enabled: 有効/無効フラグ
#   time:    通知時刻
#
# 【現在の状況】
# このテーブルは後のマイグレーションで削除された。
# リマインダー機能は別の形で再設計された。
#
# ==========================================

class CreateReminders < ActiveRecord::Migration[7.2]
  def change
    create_table :reminders do |t|
      t.references :user, null: false, foreign_key: true
      t.boolean :enabled
      t.time :time

      t.timestamps
    end
  end
end
