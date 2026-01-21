# CI/CD

## GitHub Actions

### 設定ファイル

`.github/workflows/ci.yml`

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest

    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: postgres
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    env:
      RAILS_ENV: test
      DATABASE_URL: postgres://postgres:postgres@localhost:5432/mitadake_test

    steps:
      - uses: actions/checkout@v4

      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.2'
          bundler-cache: true

      - name: Setup database
        run: |
          bundle exec rails db:test:prepare

      - name: Run RuboCop
        run: bundle exec rubocop

      - name: Run tests
        run: bundle exec rspec
```

## CI チェック項目

1. **RuboCop**: コードスタイルチェック
2. **RSpec**: テスト実行
3. **カバレッジ**: 80%以上

## デプロイ

### Render

mainブランチにマージされると自動デプロイ。

```
main → Render → 本番環境
```

### デプロイ手順

1. PRを作成してレビュー
2. CIが全てパスすることを確認
3. mainにマージ
4. Renderが自動デプロイ

## 本番環境の確認

```bash
# Renderダッシュボードでログを確認
# https://dashboard.render.com/
```

## ロールバック

Renderダッシュボードから前のデプロイにロールバック可能。
