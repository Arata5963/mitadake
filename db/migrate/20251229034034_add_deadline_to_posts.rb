# db/migrate/20251229034034_add_deadline_to_posts.rb
# ==========================================
# 投稿に締め切り日を追加
# ==========================================
#
# 【このマイグレーションの目的】
# アクションプランの実行期限を管理するため、postsテーブルに
# deadline（締め切り日）カラムを追加する。
# 締め切り駆動型のUI/UXを実現するための基盤となる変更。
#
# 【カラムの意味】
# - deadline: アクションプランの実行期限日（date型）
#   - 既存データには作成日+7日をデフォルト値として設定
#   - インデックス付き（期日でのソート・検索を高速化）
#
# ==========================================
class AddDeadlineToPosts < ActiveRecord::Migration[7.2]
  def up
    # 1. カラムを追加（nullable）
    add_column :posts, :deadline, :date

    # 2. 既存データにデフォルト値を設定（created_at + 7日）
    execute <<-SQL
      UPDATE posts SET deadline = created_at::date + INTERVAL '7 days'
    SQL

    # 3. NOT NULL 制約を追加
    change_column_null :posts, :deadline, false

    # 4. インデックスを追加（期日でのソート・検索を高速化）
    add_index :posts, :deadline
  end

  def down
    remove_index :posts, :deadline
    remove_column :posts, :deadline
  end
end
