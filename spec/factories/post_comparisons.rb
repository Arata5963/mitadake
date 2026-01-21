# spec/factories/post_comparisons.rb
# ==========================================
# PostComparisonファクトリー（テストデータ生成）
# ==========================================
#
# 【このファクトリーの役割】
# PostComparisonモデル（動画比較）のテストデータを生成。
# 2つの動画間の関連性や比較理由を表す。
#
# 【PostComparisonの構造】
#   source_post ──比較──> target_post
#   （元の動画）         （関連動画）
#
# 【使い方】
#   create(:post_comparison)              # 基本の比較（理由なし）
#   create(:post_comparison, :with_reason)  # 比較理由付き
#
FactoryBot.define do
  factory :post_comparison do
    # association + factory: オプション
    # factory: :post を指定して、別名（source_post, target_post）で参照
    association :source_post, factory: :post  # 比較元の動画
    association :target_post, factory: :post  # 比較先の動画
    reason { nil }  # 比較理由（デフォルトはなし）

    # ======================================
    # trait（トレイト）
    # ======================================

    # 比較理由付き
    # なぜこの2つの動画を比較するのかの説明
    trait :with_reason do
      reason { "これらの動画は同じトピックについて異なる視点から解説している" }
    end
  end
end
