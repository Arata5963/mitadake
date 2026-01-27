# Postsテーブルにdeadlineカラム追加
# アクションプランの実行期限を管理する（締め切り駆動型UIの基盤）

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
