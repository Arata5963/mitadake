RSpecテストを実行してください。

## 実行コマンド

```bash
docker compose exec web rspec
```

## オプション

特定のファイルやディレクトリを指定された場合:
```bash
docker compose exec web rspec <指定されたパス>
```

## 結果の報告

- テスト結果のサマリーを報告
- 失敗したテストがあれば、失敗内容と原因を分析
- 修正が必要な場合は修正案を提示
