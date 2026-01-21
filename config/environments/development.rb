# config/environments/development.rb
# ==========================================
# 開発環境の設定
# ==========================================
#
# 【このファイルの役割】
# ローカル開発時（docker compose up）の動作を設定する。
# 開発がしやすいように、デバッグ機能やホットリロードを有効化。
#
# 【開発環境の特徴】
#   - コード変更が即座に反映される（サーバー再起動不要）
#   - エラー時に詳細な情報が表示される
#   - メールは実際に送信せず、ブラウザで確認できる
#   - SQLログが詳細に出力される
#
# 【開発環境の起動方法】
#   docker compose up
#   → http://localhost:3000 でアクセス
#
# 【メール確認方法】
#   http://localhost:3000/letter_opener
#   → 開発中に送信されたメールを確認できる
#
# ==========================================

require "active_support/core_ext/integer/time"

Rails.application.configure do
  # ==========================================
  # コードリロード設定
  # ==========================================
  # コード変更を即時反映（サーバー再起動不要）
  config.enable_reloading = true

  # アプリ起動時にコードを事前読み込みしない
  config.eager_load = false

  # エラー内容を詳細表示
  config.consider_all_requests_local = true

  # ブラウザ開発ツールでサーバー処理時間を確認可能にする
  config.server_timing = true

  # キャッシュを有効化するかどうかを切り替え（tmp/caching-dev.txt の有無で判断）
  if Rails.root.join("tmp/caching-dev.txt").exist?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true
    config.public_file_server.headers = { "cache-control" => "public, max-age=#{2.days.to_i}" }
  else
    config.action_controller.perform_caching = false
  end

  # キャッシュの保存先をメモリに設定
  config.cache_store = :memory_store

  # アップロードファイルはローカルに保存（config/storage.yml を参照）
  config.active_storage.service = :local

  # メール送信失敗時にエラーを表示する（開発中はエラーを把握するため true にする）
  config.action_mailer.raise_delivery_errors = true

  # メール送信結果をキャッシュしない
  config.action_mailer.perform_caching = false
  config.action_mailer.delivery_method = :letter_opener_web


  # 開発用メールリンクのホスト名とポート番号を指定
  config.action_mailer.default_url_options = { host: "localhost", port: 3000 }

  # 非推奨機能の警告をログに出力
  config.active_support.deprecation = :log

  # マイグレーション未実行ならページ表示時にエラー
  config.active_record.migration_error = :page_load

  # DBクエリを実行したコード行をログに強調表示
  config.active_record.verbose_query_logs = true

  # SQLログに処理の実行元情報を追加
  config.active_record.query_log_tags_enabled = true

  # バックグラウンドジョブの実行元をログに強調表示
  config.active_job.verbose_enqueue_logs = true

  # ビューに対応するファイル名をコメントで表示
  config.action_view.annotate_rendered_view_with_filenames = true

  # コントローラのbefore_actionで存在しないアクション指定があればエラー
  config.action_controller.raise_on_missing_callback_actions = true
end
