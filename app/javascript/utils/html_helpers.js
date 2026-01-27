// HTML関連ユーティリティ関数
// XSS対策、CSRFトークン取得、APIリクエスト送信などの共通処理

// HTMLエスケープ（XSS対策）
export function escapeHtml(text) {
  if (!text) return ''

  const div = document.createElement('div')  // DOM要素を使ってエスケープ
  div.textContent = text                     // textContentに設定すると自動エスケープ
  return div.innerHTML                       // エスケープ済み文字列を取得
}

// RailsのCSRFトークンを取得
export function getCsrfToken() {
  return document.querySelector('meta[name="csrf-token"]')?.content  // メタタグから取得
}

// JSON APIリクエストを送信（CSRFトークン・ヘッダー自動設定）
export async function fetchJson(url, options = {}) {
  const defaultHeaders = {
    'Content-Type': 'application/json',   // 送信形式
    'Accept': 'application/json',         // 受信形式
    'X-CSRF-Token': getCsrfToken()        // CSRF保護トークン
  }

  return fetch(url, {
    ...options,
    headers: { ...defaultHeaders, ...options.headers }  // ヘッダーをマージ
  })
}
