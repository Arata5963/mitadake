# Postsテーブルにsuggested_action_plansカラム追加
# AIが提案するアクションプランの配列をJSONBで保存

class AddSuggestedActionPlansToPosts < ActiveRecord::Migration[7.2]
  def change
    add_column :posts, :suggested_action_plans, :jsonb
  end
end
