# PostEntriesテーブルにsatisfaction_ratingカラム追加
# アクションプラン達成後の満足度を1〜5の5段階評価で記録

class AddSatisfactionRatingToPostEntries < ActiveRecord::Migration[7.2]
  def change
    # 満足度: 1-5（5段階評価）- 任意入力
    add_column :post_entries, :satisfaction_rating, :integer
    add_check_constraint :post_entries, "satisfaction_rating IS NULL OR (satisfaction_rating >= 1 AND satisfaction_rating <= 5)", name: "satisfaction_rating_range"
  end
end
