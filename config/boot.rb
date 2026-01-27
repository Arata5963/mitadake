# Rails起動時の初期化処理
# Bundler（Gem管理）とBootsnap（起動高速化）を初期化

ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)  # Gemfileの場所

require "bundler/setup"   # 全Gemを利用可能にする
require "bootsnap/setup"  # 起動高速化（コードキャッシュ）
