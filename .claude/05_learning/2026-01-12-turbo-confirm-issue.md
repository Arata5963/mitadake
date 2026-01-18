# Turbo Confirm が動作しない問題

## 発生日
2026-01-12

## 現象
- 投稿詳細ページのアクションプラン達成ボタン（チェックボックス）で確認ダイアログが表示されない
- `data-turbo-confirm` を追加するとリクエスト自体が送信されなくなる
- `onclick="return confirm(...)"` も同様に動作しない

## 環境
- Rails 7.2.2
- Turbo Rails (importmap経由)
- entry_card は `turbo_frame_tag` で囲まれている

## 動作するコード
```erb
<a href="<%= achieve_post_post_entry_path(entry.post, entry) %>"
   data-turbo-method="patch"
   style="...">
  <div>チェックボックス</div>
</a>
```

## 動作しないコード
```erb
<!-- data-turbo-confirm を追加するとリクエストが飛ばない -->
<a href="..."
   data-turbo-method="patch"
   data-turbo-confirm="達成しますか？">
</a>

<!-- onclick を追加しても動作しない -->
<a href="..."
   data-turbo-method="patch"
   onclick="if(!confirm('達成しますか？')){event.preventDefault();}">
</a>

<!-- button_to + form の turbo_confirm も動作しない -->
<%= button_to path, method: :patch,
      form: { data: { turbo_confirm: "..." } } do %>
<% end %>
```

## 試したこと
1. `button_to` with `form: { data: { turbo_confirm: ... } }` - NG
2. `form_with` with `data: { turbo_confirm: ... }` - NG
3. 素のHTML form with `onsubmit="return confirm(...)"` - NG
4. `link_to` with `data: { turbo_confirm: ... }` - NG
5. 素の `<a>` with `onclick` - NG
6. Stimulus controller for confirm - 未確認

## 暫定対応
確認ダイアログなしで動作させる:
```erb
<a href="<%= achieve_post_post_entry_path(entry.post, entry) %>"
   data-turbo-method="patch"
   style="...">
</a>
```

## 調査が必要な点
- turbo_frame_tag 内での data-turbo-confirm の動作
- Turbo のバージョンと confirm 機能の互換性
- 他のページで data-turbo-confirm が動作しているか確認
- 削除ボタン（同じentry_card内）の turbo_confirm は動作しているか

## 関連ファイル
- `app/views/post_entries/_entry_card.html.erb`
- `app/javascript/application.js`
- `config/importmap.rb`
