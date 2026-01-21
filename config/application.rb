# config/application.rb
# ==========================================
# Railsアプリケーションの全体設定
# ==========================================
#
# 【このファイルの役割】
# アプリケーション全体に影響する設定を定義する。
# 全ての環境（development/test/production）で共通の設定を書く場所。
#
# 【設定の読み込み順序】
#   1. config/boot.rb        （Bundlerの初期化）
#   2. config/application.rb （このファイル - 全体設定）
#   3. config/environments/  （環境別の設定で上書き）
#   4. config/initializers/  （個別機能の初期化）
#
# 【環境別の設定ファイル】
#   - config/environments/development.rb  # 開発環境
#   - config/environments/test.rb         # テスト環境
#   - config/environments/production.rb   # 本番環境
#
# ==========================================

require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)

module Mitadake
  class Application < Rails::Application
    # Rails 7.2 のデフォルト設定を使用
    # （新しいRailsバージョンの推奨設定が自動的に適用される）
    config.load_defaults 7.2

    # lib/ フォルダを自動読み込み対象にする
    # （assets と tasks フォルダは除外）
    config.autoload_lib(ignore: %w[assets tasks])

    # app/services フォルダをautoload対象に追加
    # （サービスクラスを require なしで使えるようにする）
    config.autoload_paths << Rails.root.join("app/services")

    # ==========================================
    # 日本語・タイムゾーン設定
    # ==========================================
    # 日本語をデフォルトロケールに設定
    # （エラーメッセージ等が日本語で表示される）
    config.i18n.default_locale = :ja

    # タイムゾーンを日本時間に設定
    # （Time.current が日本時間を返すようになる）
    config.time_zone = "Tokyo"

    # ==========================================
    # バックグラウンドジョブ設定
    # ==========================================
    # ActiveJobのアダプタをSolid Queueに設定
    # （perform_later で非同期処理を実行できる）
    # Solid Queue は Redis 不要で PostgreSQL を使用
    config.active_job.queue_adapter = :solid_queue

    # ==========================================
    # Rails Generator 設定
    # ==========================================
    # `rails generate` コマンドの動作をカスタマイズ
    config.generators do |g|
      g.skip_routes true      # ルーティング自動生成を無効化
      g.helper false          # ヘルパーファイル自動生成を無効化
      g.test_framework nil    # テストファイル自動生成を無効化
    end
  end
end
