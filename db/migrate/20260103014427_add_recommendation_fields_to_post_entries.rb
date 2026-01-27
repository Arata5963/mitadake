# PostEntriesテーブルにおすすめ機能用フィールド追加
# おすすめ度、対象者、おすすめポイントのカラムを追加

class AddRecommendationFieldsToPostEntries < ActiveRecord::Migration[7.2]
  def change
    add_column :post_entries, :recommendation_level, :integer
    add_column :post_entries, :target_audience, :text
    add_column :post_entries, :recommendation_point, :text
  end
end
