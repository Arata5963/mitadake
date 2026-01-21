# コンポーネント

## ボタン

### プライマリボタン（note風）

```html
<button style="display: inline-flex; align-items: center; gap: 4px; padding: 6px 14px; border-radius: 20px; font-size: 13px; font-weight: 600; background: #333; color: white;">
  投稿
</button>
```

### セカンダリボタン

```html
<button class="px-4 py-2 text-gray-700 bg-white border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors">
  キャンセル
</button>
```

### デンジャーボタン

```html
<button class="px-4 py-2 text-white bg-red-600 rounded-lg hover:bg-red-700 transition-colors">
  削除
</button>
```

### アイコンボタン

```html
<button class="p-2 text-gray-500 hover:text-gray-700 hover:bg-gray-100 rounded-lg transition-colors">
  <svg class="w-5 h-5">...</svg>
</button>
```

---

## カード

### 投稿カード

```html
<article class="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden hover:shadow-md transition-shadow">
  <div class="aspect-video">
    <img src="thumbnail.jpg" class="w-full h-full object-cover" />
  </div>
  <div class="p-4">
    <div class="flex items-center gap-3 mb-2">
      <img src="avatar.jpg" class="w-8 h-8 rounded-full" />
      <span class="text-sm font-medium text-gray-900">ユーザー名</span>
    </div>
    <h3 class="font-semibold text-gray-900 line-clamp-2">タイトル</h3>
    <p class="text-sm text-gray-600 mt-1 line-clamp-2">説明文</p>
  </div>
</article>
```

### シンプルカード

```html
<div class="bg-white rounded-xl shadow-sm border border-gray-200 p-4">
  <h3 class="font-semibold text-gray-900 mb-2">タイトル</h3>
  <p class="text-sm text-gray-600">内容</p>
</div>
```

---

## フォーム

### テキスト入力

```html
<input
  type="text"
  class="w-full px-4 py-3 border border-gray-200 rounded-lg text-gray-900 placeholder-gray-400 focus:border-gray-400 focus:ring-1 focus:ring-gray-400 focus:outline-none transition-colors"
  placeholder="プレースホルダー"
/>
```

### テキストエリア

```html
<textarea
  rows="4"
  class="w-full px-4 py-3 border border-gray-200 rounded-lg text-gray-900 placeholder-gray-400 focus:border-gray-400 focus:ring-1 focus:ring-gray-400 focus:outline-none transition-colors resize-none"
  placeholder="プレースホルダー"
></textarea>
```

### エラー状態

```html
<input class="border border-red-500 rounded-lg focus:border-red-500 focus:ring-1 focus:ring-red-500" />
<p class="text-sm text-red-600 mt-1">エラーメッセージ</p>
```

---

## バッジ

```html
<!-- 達成済み -->
<span class="px-2 py-1 bg-green-100 text-green-700 text-xs font-medium rounded-full">達成済み</span>

<!-- 未達成 -->
<span class="px-2 py-1 bg-gray-100 text-gray-600 text-xs font-medium rounded-full">未達成</span>

<!-- エラー -->
<span class="px-2 py-1 bg-red-100 text-red-700 text-xs font-medium rounded-full">失敗</span>
```

---

## フラッシュメッセージ

```html
<!-- 成功 -->
<div class="bg-green-50 border-l-4 border-green-500 p-4 rounded-r-lg">
  <p class="text-green-700 font-medium">投稿を作成しました</p>
</div>

<!-- エラー -->
<div class="bg-red-50 border-l-4 border-red-500 p-4 rounded-r-lg">
  <p class="text-red-700 font-medium">エラーが発生しました</p>
</div>
```

---

## ローディング

### スピナー

```html
<div class="animate-spin w-6 h-6 border-2 border-gray-200 border-t-gray-600 rounded-full"></div>
```

### スケルトン

```html
<div class="animate-pulse">
  <div class="aspect-video bg-gray-200 rounded-xl mb-4"></div>
  <div class="h-4 bg-gray-200 rounded w-3/4 mb-2"></div>
  <div class="h-4 bg-gray-200 rounded w-1/2"></div>
</div>
```

---

## 空状態

```html
<div class="text-center py-12">
  <div class="w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-4">
    <svg class="w-8 h-8 text-gray-400">...</svg>
  </div>
  <h3 class="text-lg font-semibold text-gray-900 mb-2">投稿がありません</h3>
  <p class="text-gray-500 mb-6">最初の投稿を作成しましょう</p>
</div>
```
