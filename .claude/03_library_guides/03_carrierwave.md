# CarrierWave

## 概要

ファイルアップロード用ライブラリ。本番環境ではCloudinaryと連携。

## 設定

### Gemfile

```ruby
gem 'carrierwave'
gem 'cloudinary'
```

### 初期化

```ruby
# config/initializers/carrierwave.rb
CarrierWave.configure do |config|
  if Rails.env.production?
    config.storage = :cloudinary
  else
    config.storage = :file
  end
end
```

## Uploaderの作成

```ruby
# app/uploaders/avatar_uploader.rb
class AvatarUploader < CarrierWave::Uploader::Base
  include Cloudinary::CarrierWave if Rails.env.production?

  # ストレージ設定
  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  # 許可する拡張子
  def extension_allowlist
    %w[jpg jpeg png gif webp]
  end

  # ファイルサイズ制限
  def size_range
    1..5.megabytes
  end

  # デフォルト画像
  def default_url
    "/images/default_avatar.png"
  end
end
```

## モデルへのマウント

```ruby
# app/models/user.rb
class User < ApplicationRecord
  mount_uploader :avatar, AvatarUploader
end
```

## フォームでの使用

```erb
<%= form_with model: @user do |f| %>
  <div>
    <%= f.label :avatar, 'プロフィール画像' %>
    <%= f.file_field :avatar, accept: 'image/*', class: 'block w-full' %>
  </div>

  <% if @user.avatar.present? %>
    <div class="mt-4">
      <p class="text-sm text-gray-500">現在の画像:</p>
      <%= image_tag @user.avatar.url, class: 'w-20 h-20 rounded-full object-cover' %>
    </div>
  <% end %>

  <%= f.submit '保存' %>
<% end %>
```

## コントローラー

```ruby
# app/controllers/users_controller.rb
class UsersController < ApplicationController
  def update
    if @user.update(user_params)
      redirect_to @user, notice: '更新しました'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :avatar)
  end
end
```

## 画像表示

```erb
<!-- 画像がある場合のみ表示 -->
<% if user.avatar.present? %>
  <%= image_tag user.avatar.url, class: 'w-full h-full object-cover' %>
<% else %>
  <div class="w-full h-full bg-gray-200 flex items-center justify-center">
    <span class="text-gray-400">No Image</span>
  </div>
<% end %>
```

## バリデーション

```ruby
# app/models/user.rb
class User < ApplicationRecord
  mount_uploader :avatar, AvatarUploader

  validate :avatar_size_validation

  private

  def avatar_size_validation
    if avatar.present? && avatar.file.size > 5.megabytes
      errors.add(:avatar, 'は5MB以下にしてください')
    end
  end
end
```

## Cloudinary設定（本番環境）

```yaml
# config/cloudinary.yml
production:
  cloud_name: <%= ENV['CLOUDINARY_CLOUD_NAME'] %>
  api_key: <%= ENV['CLOUDINARY_API_KEY'] %>
  api_secret: <%= ENV['CLOUDINARY_API_SECRET'] %>
```

### 環境変数

```
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret
```
