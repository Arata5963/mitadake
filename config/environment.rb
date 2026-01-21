# config/environment.rb
# ==========================================
# Railsアプリケーションの初期化
# ==========================================
#
# 【このファイルの役割】
# Railsアプリケーションを初期化して使用可能な状態にする。
# config.ru、bin/rails などから呼び出される。
#
# 【初期化の流れ】
#   1. application.rb を読み込み（設定の定義）
#   2. Rails.application.initialize! で初期化実行
#      - config/initializers/ 内のファイルが全て実行される
#      - データベース接続が確立される
#      - ルーティングが読み込まれる
#
# 【注意点】
# このファイルを編集することはほとんどない。
# 通常は application.rb や initializers/ で設定を行う。
#
# ==========================================

# Railsアプリケーションの設定を読み込む
require_relative "application"

# Railsアプリケーションを初期化
# （この時点で全ての設定が適用され、アプリが使用可能になる）
Rails.application.initialize!
