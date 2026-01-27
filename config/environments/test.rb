# テスト環境の設定
# RSpecテストが高速かつ安定して実行されるように最適化

Rails.application.configure do
  config.enable_reloading = false                    # リロード無効
  config.eager_load = ENV["CI"].present?             # CIでは事前読み込み有効
  config.public_file_server.headers = { "cache-control" => "public, max-age=3600" }
  config.consider_all_requests_local = true          # エラー詳細を表示
  config.cache_store = :null_store                   # キャッシュ無効
  config.action_dispatch.show_exceptions = :rescuable
  config.action_controller.allow_forgery_protection = false  # CSRF保護無効
  config.active_storage.service = :test

  # メール設定（実際に送信せず配列に蓄積）
  config.action_mailer.delivery_method = :test
  config.action_mailer.default_url_options = { host: "example.com" }

  config.active_support.deprecation = :stderr        # 非推奨警告を標準エラー出力
  config.action_controller.raise_on_missing_callback_actions = true
  config.hosts = []                                  # ホスト制限なし
end
