# カラー・タイポグラフィ

## カラーパレット

### メインカラー

| 用途 | Tailwind / HEX | 使用場面 |
|------|----------------|----------|
| ページ背景 | `bg-white` / `bg-gray-50` | ページ全体 |
| カード背景 | `bg-white` | カード、モーダル |
| メインテキスト | `text-gray-900` / #111827 | 見出し、重要テキスト |
| 本文テキスト | `text-gray-700` / #374151 | 本文、説明文 |
| サブテキスト | `text-gray-500` / #6B7280 | キャプション、補足 |
| プライマリボタン | `#333` | CTAボタン |
| ボーダー | `border-gray-200` / #E5E7EB | カード境界、区切り |

### ボタンカラー

| 状態 | 背景 | テキスト |
|------|------|----------|
| プライマリ | `#333` | `white` |
| プライマリ:hover | `opacity: 0.8` | `white` |
| セカンダリ | `white` | `gray-700` |
| セカンダリ:hover | `gray-50` | `gray-900` |

### システムカラー

| 用途 | Tailwind |
|------|----------|
| 成功 | `text-green-600` / `bg-green-50` |
| 警告 | `text-amber-600` / `bg-amber-50` |
| エラー | `text-red-600` / `bg-red-50` |
| 情報 | `text-blue-600` / `bg-blue-50` |

---

## タイポグラフィ

### フォントファミリー

```css
font-family: 'Inter', 'Noto Sans JP', system-ui, sans-serif;
```

Tailwind: `font-sans`（デフォルト）

### フォントサイズ階層

| 用途 | Tailwind | サイズ | Weight |
|------|----------|--------|--------|
| ページタイトル | `text-2xl` / `text-3xl` | 24px / 30px | `font-bold` |
| セクション見出し | `text-xl` | 20px | `font-semibold` |
| カードタイトル | `text-lg` | 18px | `font-semibold` |
| 本文 | `text-base` | 16px | `font-normal` |
| 小テキスト | `text-sm` | 14px | `font-normal` |
| キャプション | `text-xs` | 12px | `font-medium` |

### 行間

| 用途 | Tailwind | 値 |
|------|----------|-----|
| 見出し | `leading-tight` | 1.25 |
| 本文 | `leading-relaxed` | 1.625 |
| 複数行テキスト | `leading-normal` | 1.5 |

---

## カラーコード対応表（インラインスタイル用）

| Tailwindクラス | カラーコード |
|---------------|-------------|
| `text-gray-900` | `#111827` |
| `text-gray-700` | `#374151` |
| `text-gray-600` | `#4B5563` |
| `text-gray-500` | `#6B7280` |
| `text-gray-400` | `#9CA3AF` |
| `border-gray-200` | `#E5E7EB` |
| `bg-gray-100` | `#F3F4F6` |
| `bg-gray-50` | `#F9FAFB` |
| プライマリボタン | `#333333` |
