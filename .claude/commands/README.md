# 開発コマンド集

## 日常開発

```bash
# 開発サーバー起動
docker compose up

# コンソール
docker compose exec web rails c

# マイグレーション
docker compose exec web rails db:migrate
```

## テスト

```bash
# 全テスト実行
docker compose exec web rspec

# 特定ファイル
docker compose exec web rspec spec/models/post_spec.rb

# カバレッジ付き
docker compose exec web rspec  # coverage/index.html を確認
```

## コード品質

```bash
# RuboCop（Lint）
docker compose exec web rubocop

# 自動修正
docker compose exec web rubocop -A

# セキュリティチェック
docker compose exec web bundle exec brakeman
```

## Git操作

```bash
# ブランチ作成（機能開発）
git checkout -b feature/<機能名>

# ブランチ作成（バグ修正）
git checkout -b fix/<修正内容>

# コミット前の確認
docker compose exec web rubocop && docker compose exec web rspec
```

## デプロイ

```bash
# mainにマージ後、Renderが自動デプロイ
git push origin main
```

## トラブルシューティング

```bash
# ログ確認
docker compose logs -f web

# DBリセット（開発環境のみ）
docker compose exec web rails db:reset

# キャッシュクリア
docker compose exec web rails tmp:clear
```
