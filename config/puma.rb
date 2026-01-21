# config/puma.rb
# ==========================================
# Puma Webサーバー設定
# ==========================================
#
# 【Pumaとは？】
# Railsアプリケーションを動かすWebサーバー。
# ブラウザからのリクエストを受け取り、Railsに渡す役割を持つ。
#
# 【重要な概念】
#
#   スレッド（threads）:
#   - 1つのプロセス内で複数のリクエストを同時に処理
#   - スレッド数を増やすと同時処理能力が上がる
#   - ただし、メモリ使用量も増える
#
#   ワーカー（workers）:
#   - 独立したプロセス（より強い分離）
#   - 本番環境で複数ワーカーを使うとより安定する
#   - WEB_CONCURRENCY 環境変数で制御
#
# 【設定の調整】
#   RAILS_MAX_THREADS=5 ./bin/rails s  # スレッド数を5に設定
#   WEB_CONCURRENCY=2 ./bin/rails s    # ワーカー数を2に設定
#
# 【本番環境（Render）での注意】
#   - Free プラン（512MB）ではメモリ不足に注意
#   - スレッド数・ワーカー数は控えめに設定
#
# ==========================================

# スレッド数の設定
# RAILS_MAX_THREADS 環境変数で制御可能（デフォルト: 3）
threads_count = ENV.fetch("RAILS_MAX_THREADS", 3)
threads threads_count, threads_count

# Specifies the `port` that Puma will listen on to receive requests; default is 3000.
port ENV.fetch("PORT", 3000)

# Allow puma to be restarted by `bin/rails restart` command.
plugin :tmp_restart

# Run the Solid Queue supervisor inside of Puma for single-server deployments
plugin :solid_queue if ENV["SOLID_QUEUE_IN_PUMA"]

# Specify the PID file. Defaults to tmp/pids/server.pid in development.
# In other environments, only set the PID file if requested.
pidfile ENV["PIDFILE"] if ENV["PIDFILE"]
