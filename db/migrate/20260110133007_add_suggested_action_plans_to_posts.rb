class AddSuggestedActionPlansToPosts < ActiveRecord::Migration[7.2]
  def change
    add_column :posts, :suggested_action_plans, :jsonb
  end
end
