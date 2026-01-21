# config/environments/test.rb
# ==========================================
# テスト環境の設定
# ==========================================
#
# 【このファイルの役割】
# RSpec テスト実行時の動作を設定する。
# テストが高速かつ安定して実行されるように最適化。
#
# 【テスト環境の特徴】
#   - データベースは毎回クリーンな状態にリセットされる
#   - メールは実際に送信されず、配列に蓄積される
#   - キャッシュは無効化される（副作用を防ぐ）
#   - 外部HTTPリクエストはブロックされる（WebMock）
#
# 【テスト実行方法】
#   docker compose exec web rspec          # 全テスト実行
#   docker compose exec web rspec spec/models/  # モデルテストのみ
#   docker compose exec web rspec --format doc  # 詳細表示
#
# 【テストで使用可能なメソッド】
#   ActionMailer::Base.deliveries  # 送信されたメールの配列
#   assigns(:変数名)               # コントローラのインスタンス変数
#
# ==========================================

# テスト環境はテストスイート専用。
# テストデータベースはテスト実行ごとにリセットされる。

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # While tests run files are not watched, reloading is not necessary.
  config.enable_reloading = false

  # Eager loading loads your entire application. When running a single test locally,
  # this is usually not necessary, and can slow down your test suite. However, it's
  # recommended that you enable it in continuous integration systems to ensure eager
  # loading is working properly before deploying your code.
  config.eager_load = ENV["CI"].present?

  # Configure public file server for tests with cache-control for performance.
  config.public_file_server.headers = { "cache-control" => "public, max-age=3600" }

  # Show full error reports.
  config.consider_all_requests_local = true
  config.cache_store = :null_store

  # Render exception templates for rescuable exceptions and raise for other exceptions.
  config.action_dispatch.show_exceptions = :rescuable

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false

  # Store uploaded files on the local file system in a temporary directory.
  config.active_storage.service = :test

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  # Set host to be used by links generated in mailer templates.
  config.action_mailer.default_url_options = { host: "example.com" }

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :stderr

  # Raises error for missing translations.
  # config.i18n.raise_on_missing_translations = true

  # Annotate rendered view with file names.
  # config.action_view.annotate_rendered_view_with_filenames = true

  # Raise error when a before_action's only/except options reference missing actions.
  config.action_controller.raise_on_missing_callback_actions = true
  config.hosts = []
end
