Pull Requestを作成してください。

## 手順

1. `git status`で現在の状態を確認
2. `git diff`で変更内容を確認
3. 未コミットの変更があれば、適切なコミットメッセージでコミット
4. `git push -u origin <ブランチ名>`でプッシュ
5. `gh pr create`でPRを作成

## PRフォーマット

```
gh pr create --title "<日本語タイトル>" --body "$(cat <<'EOF'
## 概要
<変更内容を1-2行で説明>

## 変更内容
- `ファイルパス`: 変更内容

## テスト方法
1. 手順
EOF
)"
```

## 注意事項

- PRタイトルは日本語で簡潔に
- セクション名は日本語（概要、変更内容、テスト方法）
- `Generated with Claude Code`フッターは付けない
- mainブランチの場合は警告して中止
