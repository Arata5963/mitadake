# lib/tasks/cleanup.rake
# 定期実行用クリーンアップタスク

namespace :cleanup do
  desc "期限切れのアクションプランを削除"
  task expired_entries: :environment do
    puts "[#{Time.current}] 期限切れアクションプラン削除を開始..."

    expired_entries = PostEntry.expired
    count = expired_entries.count

    if count > 0
      expired_entries.destroy_all
      puts "  #{count}件の期限切れアクションプランを削除しました"
    else
      puts "  削除対象なし"
    end

    puts "[#{Time.current}] 完了"
  end
end
