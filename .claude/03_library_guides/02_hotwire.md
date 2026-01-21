# Hotwire (Turbo + Stimulus)

## 概要

Rails 7標準のフロントエンドフレームワーク。SPAのような体験をサーバーサイドレンダリングで実現。

## Turbo

### Turbo Drive

ページ遷移を自動的にAjax化。特別な設定不要。

```erb
<!-- 通常のリンクは自動的にTurbo Drive対応 -->
<%= link_to '投稿一覧', posts_path %>
```

### Turbo Frame

ページの一部だけを更新。

```erb
<!-- 親ページ -->
<%= turbo_frame_tag "post_#{@post.id}" do %>
  <div class="post-card">
    <%= @post.title %>
    <%= link_to '編集', edit_post_path(@post) %>
  </div>
<% end %>

<!-- 編集ページ -->
<%= turbo_frame_tag "post_#{@post.id}" do %>
  <%= form_with model: @post do |f| %>
    <%= f.text_field :title %>
    <%= f.submit '更新' %>
  <% end %>
<% end %>
```

### Turbo Stream

リアルタイム更新。

```ruby
# app/controllers/posts_controller.rb
def create
  @post = current_user.posts.build(post_params)

  respond_to do |format|
    if @post.save
      format.turbo_stream
      format.html { redirect_to @post }
    else
      format.html { render :new, status: :unprocessable_entity }
    end
  end
end
```

```erb
<!-- app/views/posts/create.turbo_stream.erb -->
<%= turbo_stream.prepend "posts" do %>
  <%= render @post %>
<% end %>

<%= turbo_stream.update "flash" do %>
  <div class="bg-green-50 border-l-4 border-green-500 p-4">
    投稿を作成しました
  </div>
<% end %>
```

### Turbo Streamアクション

| アクション | 説明 |
|-----------|------|
| `append` | 末尾に追加 |
| `prepend` | 先頭に追加 |
| `replace` | 要素全体を置換 |
| `update` | 内部コンテンツを更新 |
| `remove` | 要素を削除 |

## Stimulus

### 基本構造

```javascript
// app/javascript/controllers/toggle_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content"]
  static values = { open: Boolean }
  static classes = ["hidden"]

  toggle() {
    this.openValue = !this.openValue
  }

  openValueChanged() {
    this.contentTarget.classList.toggle(this.hiddenClass, !this.openValue)
  }
}
```

```erb
<div data-controller="toggle" data-toggle-open-value="false" data-toggle-hidden-class="hidden">
  <button data-action="click->toggle#toggle">切り替え</button>
  <div data-toggle-target="content" class="hidden">
    コンテンツ
  </div>
</div>
```

### よく使うパターン

#### フォームの自動送信

```javascript
// app/javascript/controllers/auto_submit_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  submit() {
    this.element.requestSubmit()
  }
}
```

```erb
<%= form_with url: search_path, data: { controller: "auto-submit" } do |f| %>
  <%= f.select :category, options, {}, data: { action: "change->auto-submit#submit" } %>
<% end %>
```

#### 文字数カウント

```javascript
// app/javascript/controllers/char_count_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "count"]
  static values = { max: Number }

  count() {
    const length = this.inputTarget.value.length
    this.countTarget.textContent = `${length}/${this.maxValue}`
  }
}
```

## 命名規則

| JavaScript | HTML |
|------------|------|
| `toggle_controller.js` | `data-controller="toggle"` |
| `autoSubmit_controller.js` | `data-controller="auto-submit"` |
| `static targets = ["content"]` | `data-toggle-target="content"` |
| `static values = { open: Boolean }` | `data-toggle-open-value="true"` |
| `toggle()` | `data-action="click->toggle#toggle"` |
