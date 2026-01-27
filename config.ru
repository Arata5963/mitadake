# Rackアプリケーション起動設定
# PumaがこのファイルからRailsを起動

require_relative "config/environment"

run Rails.application
Rails.application.load_server
