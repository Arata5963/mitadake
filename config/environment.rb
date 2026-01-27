# Railsアプリケーションの初期化
# config.ru、bin/railsなどから呼び出される

require_relative "application"    # 設定を読み込む
Rails.application.initialize!     # アプリを初期化
