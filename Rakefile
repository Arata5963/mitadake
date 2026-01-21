# Rakefile
# ==========================================
# rails コマンドの裏側で使われる設定ファイル
# ==========================================
#
# 【重要】あなたは既にこのファイルを使っています！
#
#   docker compose exec web rails db:migrate
#                         ↓
#              内部で Rakefile を読み込んでいる
#
#   つまり「rails db:migrate」=「rake db:migrate」です。
#   Rails 5 以降、rake は rails に統合されました。
#
# 【このファイルがないと困ること】
#   - rails db:migrate が動かない（テーブル変更不可）
#   - rails db:seed が動かない（初期データ投入不可）
#   - rails routes が動かない（URL一覧表示不可）
#   - 本番デプロイが失敗する
#
# 【このファイルの中身】
#   たった2行だが、これで全ての rails コマンドが使えるようになる。
#
#   require_relative "config/application"  ← Rails を読み込む
#   Rails.application.load_tasks           ← コマンド群を有効化
#
# 【よく使うコマンド】
#   rails db:migrate   # DBのテーブル構造を更新
#   rails db:seed      # 初期データを投入
#   rails db:rollback  # 最後のマイグレーションを取り消す
#   rails routes       # URL一覧を表示
#   rails -T           # 使えるコマンド一覧
#
# ==========================================

# Rails アプリケーションを読み込む
require_relative "config/application"

# rails db:migrate などのコマンドを使えるようにする
Rails.application.load_tasks
