# 本番環境の設定
# セキュリティ・パフォーマンス・安定性を重視した設定（Render.com向け）

require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.enable_reloading = false  # コードリロード無効
  config.eager_load = true         # 起動時に全コードを読み込み（高速化）
  config.consider_all_requests_local = false                                           # エラー詳細を非表示
  config.action_controller.perform_caching = true                                      # キャッシュ有効
  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}" }
  config.active_storage.service = :local

  # SSL設定
  config.assume_ssl = true   # リバースプロキシ経由のSSL
  config.force_ssl = true    # HTTPS強制

  # ログ設定（STDOUTに出力、Renderが収集）
  config.log_tags = [ :request_id ]
  config.logger = ActiveSupport::TaggedLogging.new(Logger.new(STDOUT))
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")
  config.silence_healthcheck_path = "/up"
  config.active_support.report_deprecations = false

  # キャッシュ・ジョブ設定
  config.cache_store = :solid_cache_store
  config.active_job.queue_adapter = :solid_queue
  config.solid_queue.connects_to = { database: { writing: :queue } }

  # メール設定
  config.action_mailer.default_url_options = { host: "www.mitadake.com" }

  config.i18n.fallbacks = true                              # 翻訳フォールバック有効
  config.active_record.dump_schema_after_migration = false  # マイグレーション後のスキーマダンプ無効
  config.active_record.attributes_for_inspect = [ :id ]     # inspectで:idのみ表示

  # 許可するホスト
  config.hosts = [
    "mitadake.com",
    "www.mitadake.com",
    "mvp-hello-world.onrender.com"  # 移行期間中は残す
  ]
  config.host_authorization = { exclude: ->(request) { request.path == "/up" } }
end
