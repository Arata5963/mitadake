# db/migrate/20260110133007_add_suggested_action_plans_to_posts.rb
# ==========================================
# 投稿にAI提案アクションプランカラムを追加
# ==========================================
#
# 【このマイグレーションの目的】
# AIが生成したおすすめアクションプランを保存するカラムを追加する。
# ユーザーがアクションプランを考える際の参考として提示される。
#
# 【カラムの意味】
# - suggested_action_plans: AIが提案するアクションプランの配列（JSONB）
#   - 例: ["毎日10分の瞑想", "週3回の運動", "読書習慣"]
#   - 動画の内容を分析して自動生成
#
# ==========================================
class AddSuggestedActionPlansToPosts < ActiveRecord::Migration[7.2]
  def change
    add_column :posts, :suggested_action_plans, :jsonb
  end
end
