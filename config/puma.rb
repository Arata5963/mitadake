# Puma Webサーバー設定
# スレッド数・ポート番号などを環境変数で制御可能

threads_count = ENV.fetch("RAILS_MAX_THREADS", 3)  # スレッド数（デフォルト: 3）
threads threads_count, threads_count

port ENV.fetch("PORT", 3000)  # リッスンポート

plugin :tmp_restart                                # rails restartコマンド対応
plugin :solid_queue if ENV["SOLID_QUEUE_IN_PUMA"]  # Solid Queue統合

pidfile ENV["PIDFILE"] if ENV["PIDFILE"]           # PIDファイル（指定時のみ）
