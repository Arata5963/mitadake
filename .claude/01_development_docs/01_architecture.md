# アーキテクチャ設計

## 技術スタック

```
フロントエンド層
├── Hotwire (Turbo + Stimulus)
├── Tailwind CSS
└── ERB テンプレート

アプリケーション層
├── Ruby on Rails 7.2
├── MVC + Service層
└── RESTful設計

データ層
├── PostgreSQL
└── AWS S3（画像ストレージ）

インフラ層
├── Docker（開発環境）
├── Render（本番環境）
├── Solid Queue（ジョブキュー）
└── GitHub Actions（CI/CD）
```

## ディレクトリ構成

```
app/
├── controllers/
│   ├── application_controller.rb
│   ├── pages_controller.rb          # 静的ページ
│   ├── posts_controller.rb          # YouTube動画
│   ├── post_entries_controller.rb   # アクションプラン
│   ├── users_controller.rb          # マイページ
│   └── api/
│       └── presigned_urls_controller.rb  # S3署名付きURL
├── models/
│   ├── user.rb
│   ├── post.rb
│   ├── post_entry.rb
│   ├── entry_like.rb
│   └── achievement.rb
├── services/
│   ├── gemini_service.rb            # AI要約・提案
│   ├── youtube_service.rb           # YouTube API
│   └── transcript_service.rb        # 字幕取得
└── views/
    ├── layouts/
    ├── pages/
    ├── posts/
    ├── post_entries/
    └── users/
```

## 主要コントローラー

| コントローラー | 役割 |
|---------------|------|
| PagesController | ホーム、ランディングページ |
| PostsController | YouTube動画CRUD、検索、AI機能 |
| PostEntriesController | アクションプランCRUD、達成記録 |
| UsersController | マイページ、プロフィール |
| Api::PresignedUrlsController | S3画像アップロード |

## サービス層

| サービス | 役割 |
|---------|------|
| GeminiService | Gemini API連携（要約・提案生成） |
| YoutubeService | YouTube Data API連携（動画検索・情報取得） |
| TranscriptService | YouTube字幕取得（Python経由） |

## 認証

- **Devise**: メール/パスワード認証
- **OmniAuth**: Googleログイン
- `current_user`スコープで認可制御
