require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)

module Mitadake
  class Application < Rails::Application
    config.load_defaults 7.2

    config.autoload_lib(ignore: %w[assets tasks])

    # app/services をautoload対象に追加
    config.autoload_paths << Rails.root.join("app/services")

    # 日本語をデフォルトロケールに設定
    config.i18n.default_locale = :ja

    # タイムゾーンを日本時間に設定
    config.time_zone = "Tokyo"

    # ActiveJobのアダプタをSidekiqに設定
    config.active_job.queue_adapter = :sidekiq
    # Rails generatorの設定
    config.generators do |g|
      g.skip_routes true      # ルーティング自動生成を無効化
      g.helper false          # ヘルパーファイル自動生成を無効化
      g.test_framework nil    # テストファイル自動生成を無効化
    end
  end
end
