# config/boot.rb
# ==========================================
# Railsアプリケーション起動時の初期化処理
# ==========================================
#
# 【このファイルの役割】
# Railsが起動する最初の段階で実行される。
# Bundler（Gem管理）とBootsnap（起動高速化）を初期化する。
#
# 【起動の流れ】
#   1. boot.rb（このファイル）が最初に読み込まれる
#   2. Bundlerが Gemfile を読み込んで全Gemを利用可能にする
#   3. Bootsnapがキャッシュを有効化して起動を高速化
#   4. application.rb でRailsの設定が読み込まれる
#   5. environment.rb でRailsアプリが初期化される
#
# 【注意点】
# このファイルを編集することはほとんどない。
# Rails標準の起動プロセスを変更したい場合のみ編集する。
#
# ==========================================

# Gemfile の場所を環境変数で指定（未設定なら自動検出）
ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

# Bundler: Gemfile に書かれた全てのGemを利用可能にする
require "bundler/setup"

# Bootsnap: 起動を高速化（コードをキャッシュして再読み込みを省略）
# 開発時のサーバー起動が速くなる
require "bootsnap/setup"
