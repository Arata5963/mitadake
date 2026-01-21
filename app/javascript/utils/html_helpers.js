// app/javascript/utils/html_helpers.js
// HTML関連のユーティリティ関数

/**
 * HTMLエスケープ
 * XSS対策のためユーザー入力をエスケープ
 * @param {string} text - エスケープする文字列
 * @returns {string} エスケープされた文字列
 */
export function escapeHtml(text) {
  if (!text) return ''
  const div = document.createElement('div')
  div.textContent = text
  return div.innerHTML
}

/**
 * CSRFトークンを取得
 * @returns {string|null} CSRFトークン
 */
export function getCsrfToken() {
  return document.querySelector('meta[name="csrf-token"]')?.content
}

/**
 * JSON APIリクエストを送信
 * @param {string} url - リクエストURL
 * @param {Object} options - fetch オプション
 * @returns {Promise<Response>}
 */
export async function fetchJson(url, options = {}) {
  const defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'X-CSRF-Token': getCsrfToken()
  }

  return fetch(url, {
    ...options,
    headers: {
      ...defaultHeaders,
      ...options.headers
    }
  })
}
