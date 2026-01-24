# lib/tasks/cleanup.rake
# ==========================================
# データクリーンアップタスク
# ==========================================
#
# 【使い方】
#   docker compose exec web rails cleanup:empty_posts
#

namespace :cleanup do
  desc "エントリーのない空のPostを削除する"
  task empty_posts: :environment do
    puts "空のPostを検索中..."

    # エントリーがないPostを取得
    empty_posts = Post.left_joins(:post_entries)
                      .group("posts.id")
                      .having("COUNT(post_entries.id) = 0")

    count = empty_posts.count.keys.length

    if count == 0
      puts "空のPostはありませんでした。"
    else
      puts "#{count}件の空のPostが見つかりました。削除します..."

      # 削除実行
      Post.where(id: empty_posts.pluck(:id)).destroy_all

      puts "完了しました。"
    end
  end
end
