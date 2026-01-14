#!/usr/bin/env bash
# exit on error
set -o errexit

echo "Starting build process..."

# Ruby と Bundler のバージョンを確認
echo "Ruby version: $(ruby -v)"
echo "Bundler version: $(bundle -v)"

# gems をインストール
echo "Installing gems..."
bundle config set --local deployment 'true'
bundle config set --local without 'development test'
bundle install

# アセットをプリコンパイル
echo "Precompiling assets..."
bundle exec rails assets:precompile

# データベースマイグレーションを実行（SolidQueueテーブルも含む）
echo "Running database migrations..."
bundle exec rails db:migrate

echo "Build completed successfully!"