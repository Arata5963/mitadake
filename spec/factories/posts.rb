# spec/factories/posts.rb
# ==========================================
# Postファクトリー（テストデータ生成）
# ==========================================
#
# 【このファクトリーの役割】
# Postモデル（YouTube動画）のテストデータを生成する。
# 動画のタイトル、URL、チャンネル情報などを自動生成。
#
# 【使い方】
#   create(:post)                    # 基本の動画
#   create(:post, :with_user)        # ユーザー関連付きの動画
#   create(:post, :with_entries)     # エントリー（アクションプラン）付き
#   create(:post, youtube_title: "Rails入門")  # タイトル指定
#
# 【YouTube URLの構造】
#   https://www.youtube.com/watch?v=XXXXXXXXXXX
#                                   └─ 11文字のビデオID
#
FactoryBot.define do
  factory :post do
    # 必須項目
    action_plan { Faker::Lorem.sentence(word_count: 10) }  # ランダムな文章
    # YouTube URLを動的に生成（11文字のランダムなビデオID）
    youtube_url { "https://www.youtube.com/watch?v=#{Faker::Alphanumeric.alphanumeric(number: 11)}" }
    youtube_title { Faker::Lorem.sentence(word_count: 5) }  # 動画タイトル
    youtube_channel_name { Faker::Name.name }               # チャンネル名

    # ======================================
    # trait（トレイト）
    # ======================================

    # ユーザー付き（任意）
    # association :user → Userファクトリーから自動生成して関連付け
    trait :with_user do
      association :user
    end

    # 関連データ（PostEntry）付き
    # 動画に対するアクションプランを持つテストデータ
    trait :with_entries do
      # transient = ファクトリー内だけで使う一時的な変数
      # DBには保存されない
      transient do
        entry_user { nil }  # エントリーを作成するユーザー（指定可能）
      end

      # after(:create) = レコード作成後に実行される処理
      # post = 作成されたPostオブジェクト
      # evaluator = transient変数にアクセスするためのオブジェクト
      after(:create) do |post, evaluator|
        user = evaluator.entry_user || create(:user)  # ユーザー指定がなければ新規作成
        create(:post_entry, :action, post: post, user: user)  # エントリーを作成
      end
    end
  end
end
