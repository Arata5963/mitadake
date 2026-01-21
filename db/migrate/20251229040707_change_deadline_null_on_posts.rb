# db/migrate/20251229040707_change_deadline_null_on_posts.rb
# ==========================================
# 投稿のdeadlineカラムをNULL許可に変更
# ==========================================
#
# 【このマイグレーションの目的】
# deadlineを必須から任意に変更する。
# 締め切りを設定しない投稿（情報収集目的など）を許可するため。
#
# 【変更内容】
# - deadline: NOT NULL制約を削除してNULL許可に変更
#
# ==========================================
class ChangeDeadlineNullOnPosts < ActiveRecord::Migration[7.2]
  def change
    change_column_null :posts, :deadline, true
  end
end
