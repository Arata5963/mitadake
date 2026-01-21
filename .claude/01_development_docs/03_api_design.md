# API設計

## エンドポイント一覧

### Posts（YouTube動画）

| メソッド | パス | 説明 |
|---------|------|------|
| GET | /posts | 動画一覧 |
| GET | /posts/:id | 動画詳細 |
| POST | /posts/find_or_create | YouTube URLから動画作成/取得 |
| POST | /posts/create_with_action | 動画+アクションプラン同時作成 |
| GET | /posts/youtube_search | YouTube動画検索（JSON） |
| GET | /posts/search_posts | 既存投稿検索 |
| POST | /posts/:id/suggest_action_plans | AIアクションプラン提案 |

### PostEntries（アクションプラン）

| メソッド | パス | 説明 |
|---------|------|------|
| POST | /posts/:post_id/post_entries | 作成 |
| GET | /posts/:post_id/post_entries/:id/edit | 編集フォーム |
| PATCH | /posts/:post_id/post_entries/:id | 更新 |
| DELETE | /posts/:post_id/post_entries/:id | 削除 |
| PATCH | /posts/:post_id/post_entries/:id/achieve | 達成トグル |
| GET | /posts/:post_id/post_entries/:id/show_achievement | 達成記録取得（JSON） |
| PATCH | /posts/:post_id/post_entries/:id/update_reflection | 感想更新 |
| POST | /posts/:post_id/post_entries/:id/toggle_like | いいねトグル |

### Users

| メソッド | パス | 説明 |
|---------|------|------|
| GET | /mypage | マイページ |
| GET | /users/:id | ユーザー詳細 |
| GET | /users/:id/edit | プロフィール編集 |
| PATCH | /users/:id | プロフィール更新 |

### API

| メソッド | パス | 説明 |
|---------|------|------|
| POST | /api/presigned_urls | S3署名付きURL取得 |

## レスポンス形式

### 成功時（JSON）

```json
{
  "success": true,
  "data": { ... }
}
```

### エラー時（JSON）

```json
{
  "success": false,
  "error": "エラーメッセージ"
}
```

## 認証

- 多くのエンドポイントは`authenticate_user!`で保護
- 未認証時は`/users/sign_in`へリダイレクト
- API（JSON）は401を返す

## Turbo Stream対応

以下のアクションはTurbo Streamレスポンスに対応:
- PostEntries#achieve
- PostEntries#toggle_like
- PostEntries#update
