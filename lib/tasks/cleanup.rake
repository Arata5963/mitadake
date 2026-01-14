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

  desc "アクションプランがない投稿を削除（作成から24時間経過）"
  task empty_posts: :environment do
    puts "[#{Time.current}] 空の投稿削除を開始..."

    # 24時間以上経過 & アクションプランが0件の投稿
    empty_post_ids = Post.stale_empty.pluck(:id)
    count = empty_post_ids.size

    if count > 0
      Post.where(id: empty_post_ids).destroy_all
      puts "  #{count}件の空の投稿を削除しました"
    else
      puts "  削除対象なし"
    end

    puts "[#{Time.current}] 完了"
  end

  desc "アクションプランがなくなった投稿を削除"
  task orphan_posts: :environment do
    puts "[#{Time.current}] アクションプランのない投稿削除を開始..."

    # アクションプランが0件の投稿（作成時間は問わない）
    orphan_post_ids = Post.without_entries.pluck(:id)
    count = orphan_post_ids.size

    if count > 0
      Post.where(id: orphan_post_ids).destroy_all
      puts "  #{count}件の投稿を削除しました"
    else
      puts "  削除対象なし"
    end

    puts "[#{Time.current}] 完了"
  end

  desc "全てのクリーンアップを実行（毎日深夜実行用）"
  task all: :environment do
    puts "=" * 50
    puts "デイリークリーンアップ開始: #{Time.current}"
    puts "=" * 50

    # 1. 期限切れアクションプランを削除
    Rake::Task["cleanup:expired_entries"].invoke

    # 2. アクションプランがなくなった投稿を削除（期限切れ削除後に実行）
    Rake::Task["cleanup:orphan_posts"].invoke

    puts "=" * 50
    puts "デイリークリーンアップ完了: #{Time.current}"
    puts "=" * 50
  end
end
