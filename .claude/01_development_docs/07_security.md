# セキュリティ

## 認証

### Devise設定

- パスワード: 最小6文字
- セッション: Cookie-based
- Remember me: 対応

### OmniAuth（Google）

```ruby
# config/initializers/devise.rb
config.omniauth :google_oauth2,
  ENV['GOOGLE_CLIENT_ID'],
  ENV['GOOGLE_CLIENT_SECRET']
```

## 認可

### current_userスコープ

**必須**: 自分のリソースのみ操作可能にする

```ruby
# 良い例
def set_entry
  @entry = current_user.post_entries.find(params[:id])
end

# 悪い例（他人のデータを操作可能）
def set_entry
  @entry = PostEntry.find(params[:id])
end
```

### before_action

```ruby
class PostEntriesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_entry
  before_action :check_entry_owner, only: [:edit, :update, :destroy]

  private

  def check_entry_owner
    unless @entry.user == current_user
      redirect_to @post, alert: "他のユーザーのアクションプランは編集できません"
    end
  end
end
```

## Strong Parameters

```ruby
def entry_params
  params.require(:post_entry).permit(:content, :deadline)
end
```

## CSRF対策

- Rails標準の`protect_from_forgery`
- Turbo Streamリクエストも自動保護

## XSS対策

- ERBの自動エスケープ
- `raw`や`html_safe`は使用禁止

## SQLインジェクション対策

- Active Recordのクエリメソッドを使用
- 生SQLは原則禁止

```ruby
# 良い例
Post.where(user_id: user.id)

# 悪い例
Post.where("user_id = #{user.id}")
```

## ファイルアップロード

- 許可する拡張子を制限（jpg, png, webp）
- S3への直接アップロード（署名付きURL）

```ruby
ALLOWED_CONTENT_TYPES = %w[image/jpeg image/png image/webp].freeze
```

## 環境変数

本番環境の機密情報は環境変数で管理:

```
GOOGLE_CLIENT_ID
GOOGLE_CLIENT_SECRET
GEMINI_API_KEY
YOUTUBE_API_KEY
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
```

## セキュリティチェック

```bash
# Brakeman（静的解析）
docker compose exec web bundle exec brakeman
```
