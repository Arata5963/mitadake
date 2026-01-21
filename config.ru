# config.ru
# ==========================================
# Rack アプリケーション起動設定
# ==========================================
#
# 【このファイルの役割】
# Rack ベースの Web サーバー（Puma など）が
# Rails アプリケーションを起動するための設定ファイル。
#
# 【Rack とは？】
# Ruby Web アプリケーションと Web サーバー間の
# 標準インターフェース。Rails は Rack 上で動作する。
#
# 【処理の流れ】
#   1. Puma（Web サーバー）がこのファイルを読み込む
#   2. config/environment.rb で Rails を初期化
#   3. run で Rails アプリケーションを起動
#   4. HTTP リクエストが Rails に渡される
#
# 【Middleware の追加】
# このファイルで use を使って Middleware を追加できる
#   例: use Rack::Deflater  # レスポンス圧縮
#
# ==========================================

# Rails アプリケーションを読み込む
require_relative "config/environment"

# Rails アプリケーションを Rack アプリとして起動
run Rails.application

# サーバー固有の設定を読み込む
Rails.application.load_server
