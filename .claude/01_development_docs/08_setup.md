# 環境構築

## 前提条件

- Docker / Docker Compose
- Git

## 初期セットアップ

```bash
# リポジトリをクローン
git clone https://github.com/your-username/mitadake.git
cd mitadake

# 環境変数ファイルを作成
cp .env.example .env
# .envを編集してAPIキーを設定

# Dockerコンテナを起動
docker compose up -d

# データベースをセットアップ
docker compose exec web rails db:setup

# アプリケーションにアクセス
open http://localhost:3000
```

## 環境変数

### 必須

```bash
# YouTube API
YOUTUBE_API_KEY=your_youtube_api_key

# Gemini API
GEMINI_API_KEY=your_gemini_api_key

# Google OAuth
GOOGLE_CLIENT_ID=your_google_client_id
GOOGLE_CLIENT_SECRET=your_google_client_secret
```

### 本番環境追加

```bash
# AWS S3
AWS_ACCESS_KEY_ID=your_aws_access_key
AWS_SECRET_ACCESS_KEY=your_aws_secret_key
AWS_REGION=ap-northeast-1
AWS_BUCKET=your_bucket_name

# Rails
RAILS_ENV=production
SECRET_KEY_BASE=your_secret_key_base
```

## 日常の開発コマンド

```bash
# サーバー起動
docker compose up

# バックグラウンドで起動
docker compose up -d

# コンソール
docker compose exec web rails c

# マイグレーション
docker compose exec web rails db:migrate

# テスト
docker compose exec web rspec

# Lint
docker compose exec web rubocop -a

# ログ確認
docker compose logs -f web
```

## トラブルシューティング

### コンテナが起動しない

```bash
# コンテナを再ビルド
docker compose build --no-cache
docker compose up
```

### データベースエラー

```bash
# データベースをリセット（開発環境のみ）
docker compose exec web rails db:reset
```

### キャッシュクリア

```bash
docker compose exec web rails tmp:clear
```
