# spec/factories/users.rb
# ==========================================
# Userファクトリー（テストデータ生成）
# ==========================================
#
# 【FactoryBotとは？】
# テストで使うダミーデータを簡単に作成できるGem。
# RSpecテストの中で create(:user) のように呼び出す。
#
# 【このファクトリーの役割】
# Userモデルのテストデータを生成する。
# 通常のユーザー、Googleログインユーザー、アバター付き
# ユーザーなど、様々なバリエーションを作成可能。
#
# 【使い方】
#   create(:user)                    # DBに保存されたユーザー
#   build(:user)                     # 保存されていないユーザー
#   create(:user, :from_google)      # Googleログインユーザー
#   create(:user, :with_avatar)      # アバター画像付き
#   create(:user, name: "田中太郎")   # 属性を指定して作成
#
# 【Fakerとは？】
# ランダムなダミーデータ（名前、メール等）を生成するGem。
# Faker::Name.name → "山田花子" のような値を返す。
#
FactoryBot.define do
  # factory :user → create(:user) で呼び出し可能
  factory :user do
    # 基本のユーザー（メール＋パスワードでログイン）
    # 各属性はブロック {} で囲むと、呼び出すたびに新しい値が生成される
    name { Faker::Name.name }                  # ランダムな名前
    email { Faker::Internet.unique.email }    # ユニークなメールアドレス
    password { "password123" }                 # テスト用の固定パスワード

    # ======================================
    # trait（トレイト）= 属性のバリエーション
    # ======================================
    # create(:user, :from_google) のように使う

    # Google でログインするユーザー（パスワード不要）
    # OmniAuth認証を使うユーザーのテストに使用
    trait :from_google do
      provider { "google_oauth2" }                        # OAuth2プロバイダー名
      uid { Faker::Number.number(digits: 20).to_s }       # GoogleのユーザーID
      password { nil }                                     # OAuth認証なのでパスワード不要
    end

    # アバター画像付きユーザーを作成する trait
    # 画像アップロードのテストに使用
    trait :with_avatar do
      # Rack::Test::UploadedFile = テスト用のファイルアップロードを模擬
      avatar { Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/sample_avatar.jpg"), "image/jpeg") }
    end
  end
end
