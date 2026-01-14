# app/jobs/cleanup_expired_entries_job.rb
# 期限切れの未達成エントリーを削除するジョブ
class CleanupExpiredEntriesJob < ApplicationJob
  queue_as :default

  def perform
    # 期限切れの未達成エントリーを取得して削除
    expired_entries = PostEntry.expired
    count = expired_entries.count

    if count > 0
      expired_entries.destroy_all
      Rails.logger.info("[CleanupExpiredEntriesJob] Deleted #{count} expired entries")
    else
      Rails.logger.info("[CleanupExpiredEntriesJob] No expired entries to delete")
    end
  end
end
