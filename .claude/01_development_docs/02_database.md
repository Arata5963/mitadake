# データベース設計

## ER図

```
┌─────────────────┐
│      User       │
├─────────────────┤
│ id              │──┐
│ email           │  │
│ name            │  │
│ avatar          │  │
│ favorite_quote_url│ │
└─────────────────┘  │
         │           │
         ▼           │
┌─────────────────┐  │
│      Post       │  │
├─────────────────┤  │
│ id              │←─┼──────────────────┐
│ user_id         │──┘                  │
│ youtube_url     │                     │
│ youtube_video_id│ (unique)            │
│ youtube_title   │                     │
│ youtube_channel_name│                 │
│ youtube_channel_id│                   │
│ youtube_channel_thumbnail_url│        │
└─────────────────┘                     │
         │                              │
         ▼                              │
┌─────────────────┐    ┌──────────────┐ │
│   PostEntry     │    │  EntryLike   │ │
├─────────────────┤    ├──────────────┤ │
│ id              │←───│ post_entry_id│ │
│ post_id         │────│              │ │
│ user_id         │────│ user_id      │─┘
│ content         │    └──────────────┘
│ achieved_at     │
│ reflection      │
│ result_image    │
│ thumbnail_url   │
└─────────────────┘
```

## テーブル定義

### users

| カラム | 型 | 制約 | 説明 |
|--------|-----|------|------|
| id | bigint | PK | 主キー |
| email | string | NOT NULL, UNIQUE | メールアドレス |
| encrypted_password | string | NOT NULL | 暗号化パスワード |
| name | string | | 表示名 |
| avatar | string | | アバター画像パス |
| provider | string | | OAuthプロバイダ |
| uid | string | | OAuthユーザーID |
| favorite_quote_url | string | | お気に入り動画URL |

### posts

| カラム | 型 | 制約 | 説明 |
|--------|-----|------|------|
| id | bigint | PK | 主キー |
| user_id | bigint | FK | 投稿者（nullable） |
| youtube_url | string | NOT NULL | YouTube動画URL |
| youtube_video_id | string | UNIQUE | 動画ID |
| youtube_title | string | | 動画タイトル |
| youtube_channel_name | string | | チャンネル名 |
| youtube_channel_id | string | | チャンネルID |
| youtube_channel_thumbnail_url | string | | チャンネルサムネイル |
| action_plan | text | | 旧形式（互換性のため残存） |
| ai_summary | text | | AI要約 |
| suggested_action_plans | jsonb | | AI提案アクションプラン |

### post_entries（アクションプラン）

| カラム | 型 | 制約 | 説明 |
|--------|-----|------|------|
| id | bigint | PK | 主キー |
| post_id | bigint | FK, NOT NULL | 対象動画 |
| user_id | bigint | FK | 作成者 |
| content | text | | アクションプラン内容 |
| achieved_at | datetime | | 達成日時 |
| reflection | text | | 感想（max: 500文字） |
| result_image | string | | 達成証拠画像（S3キー） |
| thumbnail_url | string | | サムネイル画像URL |

### entry_likes

| カラム | 型 | 制約 | 説明 |
|--------|-----|------|------|
| id | bigint | PK | 主キー |
| user_id | bigint | FK, NOT NULL | いいねしたユーザー |
| post_entry_id | bigint | FK, NOT NULL | 対象アクションプラン |

**インデックス**: `index_entry_likes_on_user_id_and_post_entry_id` (unique)

## アソシエーション

```ruby
class User < ApplicationRecord
  has_many :posts
  has_many :post_entries
  has_many :entry_likes
end

class Post < ApplicationRecord
  belongs_to :user, optional: true
  has_many :post_entries, dependent: :destroy
end

class PostEntry < ApplicationRecord
  belongs_to :post
  belongs_to :user
  has_many :entry_likes, dependent: :destroy
end

class EntryLike < ApplicationRecord
  belongs_to :user
  belongs_to :post_entry
end
```

## 主要スコープ

```ruby
# PostEntry
scope :recent, -> { order(created_at: :desc) }
scope :not_achieved, -> { where(achieved_at: nil) }
scope :achieved, -> { where.not(achieved_at: nil) }
```
