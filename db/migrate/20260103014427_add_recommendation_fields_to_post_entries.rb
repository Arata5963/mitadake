# db/migrate/20260103014427_add_recommendation_fields_to_post_entries.rb
# ==========================================
# エントリーにおすすめ機能用フィールドを追加
# ==========================================
#
# 【このマイグレーションの目的】
# ユーザーが動画をおすすめできる機能のため、
# おすすめ度、対象者、おすすめポイントのカラムを追加する。
#
# 【カラムの意味】
# - recommendation_level: おすすめ度（1〜5の段階評価）
# - target_audience: 対象者（「〇〇な人におすすめ」のテキスト）
# - recommendation_point: おすすめポイント（詳細な理由）
#
# ==========================================
class AddRecommendationFieldsToPostEntries < ActiveRecord::Migration[7.2]
  def change
    add_column :post_entries, :recommendation_level, :integer
    add_column :post_entries, :target_audience, :text
    add_column :post_entries, :recommendation_point, :text
  end
end
