# Devise

## 概要

ユーザー認証に使用。メール/パスワード認証を実装。

## 設定

### Gemfile

```ruby
gem 'devise'
```

### 設定ファイル

- `config/initializers/devise.rb`
- `config/locales/devise.ja.yml`

## 使用パターン

### コントローラーでの認証

```ruby
class PostsController < ApplicationController
  before_action :authenticate_user!  # ログイン必須

  def index
    @posts = current_user.posts  # current_userでログインユーザー取得
  end
end
```

### ビューでのヘルパー

```erb
<% if user_signed_in? %>
  <%= current_user.name %>
  <%= link_to 'ログアウト', destroy_user_session_path, data: { turbo_method: :delete } %>
<% else %>
  <%= link_to 'ログイン', new_user_session_path %>
<% end %>
```

### ルーティング

```ruby
# config/routes.rb
devise_for :users
```

## カスタマイズ

### ユーザー登録後のリダイレクト

```ruby
# app/controllers/application_controller.rb
def after_sign_in_path_for(resource)
  user_path(resource)
end
```

### Strong Parameters追加

```ruby
# app/controllers/application_controller.rb
before_action :configure_permitted_parameters, if: :devise_controller?

protected

def configure_permitted_parameters
  devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
  devise_parameter_sanitizer.permit(:account_update, keys: [:name])
end
```

## Turbo対応

```ruby
# app/controllers/users/sessions_controller.rb
class Users::SessionsController < Devise::SessionsController
  def destroy
    super do
      return redirect_to root_path
    end
  end
end
```

## テスト

### ログイン状態でのテスト

```ruby
# spec/rails_helper.rb
config.include Devise::Test::IntegrationHelpers, type: :request
config.include Devise::Test::IntegrationHelpers, type: :system

# spec/requests/posts_spec.rb
RSpec.describe "Posts", type: :request do
  let(:user) { create(:user) }

  before { sign_in user }

  it "投稿一覧を表示" do
    get posts_path
    expect(response).to have_http_status(:success)
  end
end
```
