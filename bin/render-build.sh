#!/usr/bin/env bash
# bin/render-build.sh
# ==========================================
# Render デプロイ用ビルドスクリプト
# ==========================================
#
# 【このファイルの役割】
# Render.com にデプロイする際に実行されるビルドスクリプト。
# GitHub の main ブランチにプッシュすると自動的に実行される。
#
# 【実行される処理】
#   1. Ruby/Bundler バージョン確認
#   2. Gem インストール（本番用のみ）
#   3. アセットプリコンパイル
#   4. データベースマイグレーション
#
# 【set -o errexit とは？】
# コマンドが失敗したらスクリプト全体を停止する。
# これにより、途中でエラーが発生した場合にデプロイが中断される。
#
# 【bundle config の意味】
#   --local deployment 'true': 本番用設定
#   --local without 'development test': 開発・テスト用Gemを除外
#
# 【Render の設定場所】
#   Render Dashboard → Settings → Build Command
#   → ./bin/render-build.sh
#
# ==========================================

# エラー発生時はスクリプトを停止
set -o errexit

echo "Starting build process..."

# Ruby と Bundler のバージョンを確認（デバッグ用）
echo "Ruby version: $(ruby -v)"
echo "Bundler version: $(bundle -v)"

# Gem をインストール（本番環境用）
echo "Installing gems..."
bundle config set --local deployment 'true'       # 本番モード
bundle config set --local without 'development test'  # 開発・テスト用を除外
bundle install

# アセットをプリコンパイル（CSS/JS の最適化）
echo "Precompiling assets..."
bundle exec rails assets:precompile

# データベースマイグレーションを実行
echo "Running database migrations..."
bundle exec rails db:migrate

echo "Build completed successfully!"