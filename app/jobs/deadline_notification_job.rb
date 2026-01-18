# frozen_string_literal: true

# 期限当日のアクションプランを通知するジョブ
# 毎朝9時に実行される
class DeadlineNotificationJob < ApplicationJob
  queue_as :default

  def perform
    today = Date.current
    notified_count = 0

    # 今日が期限の未達成アクションプランを取得
    entries_due_today = PostEntry.not_achieved.where(deadline: today).includes(:user, :post)

    entries_due_today.find_each do |entry|
      next if entry.user.blank?

      # 同じエントリに対して今日既に通知済みかチェック
      already_notified = entry.user.notifications
        .where(notifiable: entry, key: "post_entry.deadline_today")
        .where("created_at >= ?", today.beginning_of_day)
        .exists?

      next if already_notified

      # 通知を作成
      entry.notify :users, key: "post_entry.deadline_today"
      notified_count += 1

      Rails.logger.info "[DeadlineNotificationJob] Notified user##{entry.user_id} for entry##{entry.id}"
    end

    Rails.logger.info "[DeadlineNotificationJob] Created #{notified_count} deadline notifications at #{Time.current.strftime('%Y-%m-%d %H:%M')}"
  end
end
