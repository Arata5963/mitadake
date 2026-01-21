# db/migrate/20260102045235_add_satisfaction_rating_to_post_entries.rb
# ==========================================
# エントリーに満足度評価カラムを追加
# ==========================================
#
# 【このマイグレーションの目的】
# アクションプラン達成後の満足度を記録するため、
# post_entriesテーブルにsatisfaction_ratingカラムを追加する。
# 振り返り機能の一環として、達成感を数値化して記録できる。
#
# 【カラムの意味】
# - satisfaction_rating: 満足度（1〜5の5段階評価、任意入力）
#   - CHECK制約: NULLまたは1〜5の範囲
#   - 1: とても不満 〜 5: とても満足
#
# ==========================================
class AddSatisfactionRatingToPostEntries < ActiveRecord::Migration[7.2]
  def change
    # 満足度: 1-5（5段階評価）- 任意入力
    add_column :post_entries, :satisfaction_rating, :integer
    add_check_constraint :post_entries, "satisfaction_rating IS NULL OR (satisfaction_rating >= 1 AND satisfaction_rating <= 5)", name: "satisfaction_rating_range"
  end
end
