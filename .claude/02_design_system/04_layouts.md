# レイアウト

## ページレイアウト

### 基本構造

```html
<body class="min-h-screen bg-white flex flex-col">
  <!-- ヘッダー -->
  <header class="bg-white border-b border-gray-200 sticky top-0 z-40">
    ...
  </header>

  <!-- メインコンテンツ -->
  <main class="flex-1">
    ...
  </main>

  <!-- フッター（必要に応じて） -->
  <footer>
    ...
  </footer>
</body>
```

### コンテンツ幅

```html
<div class="mx-auto max-w-screen-xl px-4 sm:px-6 lg:px-8">
  <!-- コンテンツ -->
</div>
```

---

## ヘッダー

```html
<header class="bg-white border-b border-gray-200 sticky top-0 z-40">
  <div class="mx-auto max-w-screen-xl px-4">
    <div class="flex h-14 items-center justify-between">
      <!-- ロゴ -->
      <a href="/" class="text-lg font-bold text-gray-900">mitadake?</a>

      <!-- ナビゲーション -->
      <div class="flex items-center gap-4">
        <button style="background: #333; color: white; padding: 6px 14px; border-radius: 20px; font-size: 13px; font-weight: 600;">
          投稿
        </button>
        <button class="p-1 rounded-full text-gray-500 hover:text-gray-700 hover:bg-gray-100">
          <img src="avatar.jpg" class="w-8 h-8 rounded-full" />
        </button>
      </div>
    </div>
  </div>
</header>
```

---

## スペーシング

### 基本単位

| Tailwind | 値 | 用途 |
|----------|-----|------|
| `gap-1` | 4px | 極小間隔 |
| `gap-2` | 8px | 小間隔 |
| `gap-3` | 12px | 中小間隔 |
| `gap-4` | 16px | 標準間隔 |
| `gap-6` | 24px | 大間隔 |
| `gap-8` | 32px | セクション間 |

### パディング

| 用途 | Tailwind |
|------|----------|
| カード内 | `p-4` / `p-5` |
| 入力フィールド | `px-4 py-3` |
| ボタン | `px-4 py-2` |
| ページ余白 | `px-4` |

---

## グリッド

### 投稿一覧（レスポンシブ）

```html
<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
  <!-- カード -->
</div>
```

### 2カラムレイアウト

```html
<div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
  <div class="lg:col-span-2">
    <!-- メインコンテンツ -->
  </div>
  <div>
    <!-- サイドバー -->
  </div>
</div>
```

---

## ブレークポイント

| 名前 | Tailwind | 値 | 用途 |
|------|----------|-----|------|
| モバイル | デフォルト | < 640px | スマートフォン |
| sm | `sm:` | 640px | スマホ横向き |
| md | `md:` | 768px | タブレット |
| lg | `lg:` | 1024px | デスクトップ |
| xl | `xl:` | 1280px | 大画面 |

---

## 角丸・影

### 角丸

| 用途 | Tailwind |
|------|----------|
| 小 | `rounded-lg` |
| 標準 | `rounded-xl` |
| 完全円 | `rounded-full` |

### 影

| 用途 | Tailwind |
|------|----------|
| カード | `shadow-sm` |
| ホバー | `shadow-md` |
| モーダル | `shadow-xl` |
