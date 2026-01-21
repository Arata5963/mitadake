# Rakefile
# ==========================================
# Rake タスク定義ファイル
# ==========================================
#
# 【このファイルの役割】
# Rake タスクのエントリーポイント。
# Rails 標準タスクとカスタムタスクを読み込む。
#
# 【カスタムタスクの追加方法】
# lib/tasks/ フォルダに .rake ファイルを作成すると、
# 自動的にタスクとして認識される。
#
# 【例: lib/tasks/sample.rake】
#   namespace :sample do
#     desc "サンプルタスク"
#     task hello: :environment do
#       puts "Hello, World!"
#     end
#   end
#   → bin/rake sample:hello で実行
#
# 【よく使う標準タスク】
#   bin/rake -T             # タスク一覧
#   bin/rake db:migrate     # マイグレーション実行
#   bin/rake db:seed        # 初期データ投入
#   bin/rake routes         # ルーティング一覧
#   bin/rake stats          # コード統計
#
# ==========================================

# カスタムタスクは lib/tasks/*.rake に配置すると自動読み込み
require_relative "config/application"

# Rails 標準タスクを読み込む
Rails.application.load_tasks
