# 開発環境の設定
# ホットリロード、詳細エラー表示、letter_openerでのメール確認を有効化

require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.enable_reloading = true                            # コード変更を即時反映
  config.eager_load = false                                 # 起動時にコードを事前読み込みしない
  config.consider_all_requests_local = true                 # エラー詳細を表示
  config.server_timing = true                               # ブラウザ開発ツールで処理時間確認

  # キャッシュ設定（tmp/caching-dev.txt の有無で切り替え）
  if Rails.root.join("tmp/caching-dev.txt").exist?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true
    config.public_file_server.headers = { "cache-control" => "public, max-age=#{2.days.to_i}" }
  else
    config.action_controller.perform_caching = false
  end

  config.cache_store = :memory_store            # キャッシュをメモリに保存
  config.active_storage.service = :local        # ファイルをローカルに保存

  # メール設定（letter_opener_webで確認）
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.perform_caching = false
  config.action_mailer.delivery_method = :letter_opener_web
  config.action_mailer.default_url_options = { host: "localhost", port: 3000 }

  config.active_support.deprecation = :log                          # 非推奨警告をログ出力
  config.active_record.migration_error = :page_load                 # マイグレーション未実行時エラー
  config.active_record.verbose_query_logs = true                    # SQLログに実行元コードを表示
  config.active_record.query_log_tags_enabled = true                # SQLログにタグ追加
  config.active_job.verbose_enqueue_logs = true                     # ジョブログを詳細表示
  config.action_view.annotate_rendered_view_with_filenames = true   # ビューにファイル名表示
  config.action_controller.raise_on_missing_callback_actions = true # 存在しないアクション参照時エラー
end
