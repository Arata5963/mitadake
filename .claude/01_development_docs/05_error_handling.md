# エラーハンドリング

## 基本方針

1. ユーザーには日本語でわかりやすいメッセージを表示
2. ログには詳細なエラー情報を記録
3. 外部API（YouTube, Gemini）のエラーはgraceful degradation

## パターン

### バリデーションエラー

```ruby
def create
  @entry = @post.post_entries.build(entry_params)
  @entry.user = current_user

  if @entry.save
    redirect_to @post, notice: "アクションプランを投稿しました"
  else
    redirect_to @post, alert: "投稿に失敗しました: #{@entry.errors.full_messages.join(', ')}"
  end
end
```

### 外部APIエラー

```ruby
# GeminiService
def self.suggest_action_plans(...)
  # API呼び出し
rescue Faraday::Error => e
  Rails.logger.error("Gemini API error: #{e.message}")
  { success: false, error: "AI機能が一時的に利用できません" }
end

# YoutubeService
def self.fetch_video_info(youtube_url)
  # API呼び出し
rescue Google::Apis::ClientError => e
  Rails.logger.warn("YouTube API client error: #{e.message}")
  nil
rescue Google::Apis::ServerError => e
  Rails.logger.error("YouTube API server error: #{e.message}")
  nil
end
```

### 認証エラー

```ruby
class ApplicationController < ActionController::Base
  before_action :authenticate_user!

  # 未認証時のリダイレクト
  def after_sign_in_path_for(resource)
    stored_location_for(resource) || posts_path
  end
end
```

## Flashメッセージ

| タイプ | 用途 | Tailwindクラス |
|--------|------|-----------------|
| notice | 成功メッセージ | bg-green-50 border-green-500 text-green-700 |
| alert | エラーメッセージ | bg-red-50 border-red-500 text-red-700 |

## ログレベル

| レベル | 用途 |
|--------|------|
| info | 正常な操作ログ |
| warn | 軽微なエラー（API制限など） |
| error | 重大なエラー（サーバーエラーなど） |

## 404エラー

```ruby
# レコードが見つからない場合
@post = Post.find(params[:id])  # RecordNotFoundで404
```

## HTTPステータスコード

| コード | 用途 |
|--------|------|
| 200 | 成功 |
| 302 | リダイレクト |
| 401 | 未認証 |
| 404 | リソース未発見 |
| 422 | バリデーションエラー |
| 500 | サーバーエラー |
