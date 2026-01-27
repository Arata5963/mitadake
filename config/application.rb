# Railsアプリケーションの全体設定
# 全ての環境（development/test/production）で共通の設定

require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)

module Mitadake
  class Application < Rails::Application
    config.load_defaults 7.2                                   # Rails 7.2のデフォルト設定を使用

    config.autoload_lib(ignore: %w[assets tasks])              # lib/フォルダを自動読み込み
    config.autoload_paths << Rails.root.join("app/services")   # app/servicesをautoload対象に追加

    config.i18n.default_locale = :ja                           # 日本語をデフォルトに
    config.time_zone = "Tokyo"                                 # タイムゾーンを日本時間に

    config.active_job.queue_adapter = :solid_queue             # バックグラウンドジョブ設定（Redis不要）

    # Generatorの設定
    config.generators do |g|
      g.skip_routes true                                       # ルーティング自動生成を無効化
      g.helper false                                           # ヘルパーファイル自動生成を無効化
      g.test_framework nil                                     # テストファイル自動生成を無効化
    end
  end
end
