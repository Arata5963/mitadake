#!/usr/bin/env bash
# Render デプロイ用ビルドスクリプト
# Gem インストール → アセットコンパイル → DB マイグレーション

set -o errexit                                       # エラー時は停止

echo "Starting build process..."
echo "Ruby version: $(ruby -v)"
echo "Bundler version: $(bundle -v)"

echo "Installing gems..."
bundle config set --local deployment 'true'          # 本番モード
bundle config set --local without 'development test' # 開発用 Gem 除外
bundle install

echo "Precompiling assets..."
bundle exec rails assets:precompile

echo "Running database migrations..."
bundle exec rails db:migrate

echo "Build completed successfully!"
