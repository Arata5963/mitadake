# 依存ライブラリ定義
# bundle install でこのファイルに書かれたGemがインストールされる

source "https://rubygems.org"

# Rails基本フレームワーク
gem "rails", "~> 7.2.2"

# アセット管理・フロントエンド
gem "propshaft"           # 静的ファイル配信
gem "importmap-rails"     # ES6モジュール管理
gem "turbo-rails"         # ページ高速化（SPA風）
gem "stimulus-rails"      # JavaScriptフレームワーク
gem "jbuilder"            # JSON API構築

# 認証機能
gem "devise"                             # ユーザー認証
gem "omniauth-google-oauth2"             # Google OAuth
gem "omniauth-rails_csrf_protection"     # OAuthセキュリティ

# データベース・サーバー
gem "pg", "~> 1.1"        # PostgreSQL接続
gem "puma", ">= 5.0"      # Webサーバー

# OS依存
gem "tzinfo-data", platforms: %i[ windows jruby ]

# パフォーマンス・バックグラウンド処理
gem "solid_cache"                  # キャッシュ
gem "solid_queue"                  # バックグラウンドジョブ
gem "solid_cable"                  # WebSocket
gem "bootsnap", require: false     # 起動高速化

# 画像アップロード
gem "carrierwave"         # ファイルアップロード
gem "fog-aws"             # S3連携（CarrierWave用）
gem "aws-sdk-s3"          # S3直接アクセス
gem "mini_magick"         # 画像リサイズ

# その他機能
gem "kaminari", "~> 1.2"          # ページネーション
gem "ransack", "~> 4.0"           # 検索機能
gem "meta-tags"                   # OGP/SEOメタタグ
gem "google-apis-youtube_v3"      # YouTube Data API
gem "gemini-ai"                   # Gemini AI API
gem "tailwindcss-rails", "~> 4.3" # Tailwind CSS
gem "redcarpet"                   # Markdownパーサー

# 開発・テスト環境
group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "brakeman", require: false            # セキュリティチェック
  gem "rubocop-rails-omakase", require: false
  gem "bundler-audit", require: false
  gem "rspec-rails", "~> 7.1"               # テストフレームワーク
  gem "factory_bot_rails", "~> 6.4"         # テストデータ作成
  gem "faker", "~> 3.5"                     # ダミーデータ生成
end

# 開発環境のみ
group :development do
  gem "web-console"                         # ブラウザデバッグ
  gem "letter_opener_web", "~> 2.0"         # メール確認
  gem "ruby-lsp", require: false
  gem "ruby-lsp-rails", require: false
end

# テスト環境のみ
group :test do
  gem "capybara"                            # ブラウザテスト
  gem "selenium-webdriver"
  gem "shoulda-matchers", "~> 6.4"
  gem "database_cleaner-active_record"
  gem "simplecov", require: false
  gem "webmock"
  gem "vcr"
end
