# spec/factories/post_entries.rb
# ==========================================
# PostEntryファクトリー（テストデータ生成）
# ==========================================
#
# 【このファクトリーの役割】
# PostEntryモデル（アクションプラン）のテストデータを生成。
# ユーザーが動画を見て立てた行動計画を表す。
#
# 【PostEntryの状態】
#   - 未達成: achieved_at が nil
#   - 達成済み: achieved_at に日時が入っている
#   - 期限切れ: deadline < 今日の日付
#
# 【使い方】
#   create(:post_entry)                  # 基本のエントリー（期限7日後）
#   create(:post_entry, :achieved)       # 達成済みエントリー
#   create(:post_entry, :overdue)        # 期限切れエントリー
#   create(:post_entry, :without_deadline)  # 期限なし
#
FactoryBot.define do
  factory :post_entry do
    # association = 関連モデルを自動生成して紐付け
    association :post   # Postファクトリーから生成
    association :user   # Userファクトリーから生成
    content { Faker::Lorem.sentence(word_count: 8) }  # アクションプランの内容
    deadline { Date.current + 7.days }                 # 期限（デフォルト:7日後）

    # ======================================
    # trait（トレイト）
    # ======================================

    # アクションタイプ（デフォルト）
    # entry_type: 0 がデフォルトなので、特に設定不要
    trait :action do
      # Default is already action type (entry_type: 0)
    end

    # 達成済みエントリー
    # achieved_at に現在時刻を設定
    trait :achieved do
      achieved_at { Time.current }
    end

    # 期限なしエントリー
    trait :without_deadline do
      deadline { nil }
    end

    # 期限切れエントリー
    # 3日前の期限 → 今日時点で期限オーバー
    trait :overdue do
      deadline { Date.current - 3.days }
    end
  end
end
