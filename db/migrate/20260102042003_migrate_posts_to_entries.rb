# db/migrate/20260102042003_migrate_posts_to_entries.rb
# ==========================================
# 投稿データをエントリー形式に移行
# ==========================================
#
# 【このマイグレーションの目的】
# postsテーブルのaction_planデータをpost_entriesテーブルに移行する。
# 「1動画 = 1投稿」から「1動画 = 複数エントリー」のデータ構造へ変更。
# これにより、同じ動画に複数人がアクションプランを投稿できる。
#
# 【処理内容】
# 1. youtube_urlからyoutube_video_idを抽出・設定
# 2. 重複投稿（同じuser_id + youtube_video_id）をマージ
#    - コメント、応援、達成記録を古い投稿に集約
# 3. user_id + youtube_video_id のユニーク制約を追加
# 4. 既存のaction_planをPostEntryに変換
#
# 【注意】
# - 重複データはマージされるため、一部データが削除される
#
# ==========================================
class MigratePostsToEntries < ActiveRecord::Migration[7.2]
  # マイグレーション内で使用する一時的なモデル
  class Post < ApplicationRecord
    self.table_name = 'posts'

    def extract_video_id
      return nil unless youtube_url.present?

      if youtube_url.include?('youtube.com/watch')
        URI.parse(youtube_url).query&.split('&')
           &.find { |p| p.start_with?('v=') }
           &.delete_prefix('v=')
      elsif youtube_url.include?('youtu.be/')
        youtube_url.split('youtu.be/').last&.split('?')&.first
      end
    rescue URI::InvalidURIError
      nil
    end
  end

  class PostEntry < ApplicationRecord
    self.table_name = 'post_entries'
  end

  def up
    # 1. まず youtube_video_id を設定
    Post.find_each do |post|
      video_id = post.extract_video_id
      post.update_column(:youtube_video_id, video_id) if video_id.present?
    end

    # 2. 重複を検出してマージ（同じuser_id + youtube_video_idの投稿）
    duplicates = execute(<<-SQL)
      SELECT user_id, youtube_video_id, array_agg(id ORDER BY created_at) as post_ids
      FROM posts
      WHERE youtube_video_id IS NOT NULL
      GROUP BY user_id, youtube_video_id
      HAVING COUNT(*) > 1
    SQL

    duplicates.each do |row|
      post_ids = row['post_ids'].tr('{}', '').split(',').map(&:to_i)
      keep_id = post_ids.first # 最も古い投稿を残す
      delete_ids = post_ids[1..]

      delete_ids.each do |delete_id|
        # comments: 移動（重複制約なし）
        execute("UPDATE comments SET post_id = #{keep_id} WHERE post_id = #{delete_id}")

        # cheers: 重複しないものだけ移動、重複は削除
        execute(<<-SQL)
          DELETE FROM cheers
          WHERE post_id = #{delete_id}
          AND user_id IN (SELECT user_id FROM cheers WHERE post_id = #{keep_id})
        SQL
        execute("UPDATE cheers SET post_id = #{keep_id} WHERE post_id = #{delete_id}")

        # achievements: 重複しないものだけ移動、重複は削除
        execute(<<-SQL)
          DELETE FROM achievements
          WHERE post_id = #{delete_id}
          AND user_id IN (SELECT user_id FROM achievements WHERE post_id = #{keep_id})
        SQL
        execute("UPDATE achievements SET post_id = #{keep_id} WHERE post_id = #{delete_id}")
      end

      # 重複投稿を削除
      execute("DELETE FROM posts WHERE id IN (#{delete_ids.join(',')})")
    end

    # 3. ユニーク制約を追加（重複処理後）
    add_index :posts, %i[user_id youtube_video_id], unique: true

    # 4. 既存の action_plan を PostEntry に変換
    Post.where.not(action_plan: [ nil, '' ]).find_each do |post|
      PostEntry.create!(
        post_id: post.id,
        entry_type: 1, # action
        content: post.action_plan,
        deadline: post.deadline,
        achieved_at: post.achieved_at,
        created_at: post.created_at,
        updated_at: post.updated_at
      )
    end
  end

  def down
    # PostEntry を削除
    execute("DELETE FROM post_entries")

    # ユニーク制約を削除
    remove_index :posts, %i[user_id youtube_video_id]

    # youtube_video_id をクリア
    execute('UPDATE posts SET youtube_video_id = NULL')
  end
end
