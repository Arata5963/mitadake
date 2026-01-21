// app/javascript/utils/html_helpers.js
// ==========================================
// HTML関連のユーティリティ関数
// ==========================================
//
// 【このファイルの役割】
// セキュリティ対策（XSS防止）、APIリクエスト、
// CSRF保護など、Web開発で必須の共通処理をまとめたヘルパー。
//
// 【主な機能】
// 1. escapeHtml: HTMLエスケープ（XSS対策）
// 2. getCsrfToken: CSRFトークン取得
// 3. fetchJson: JSON APIリクエスト送信
//

// ------------------------------------------
// HTMLエスケープ
// ------------------------------------------
// 【何をする関数？】
// ユーザー入力をHTMLに挿入する前にエスケープ処理。
// XSS（クロスサイトスクリプティング）攻撃を防ぐために必須。
//
// 【XSS攻撃とは？】
// 悪意あるユーザーが <script>悪いコード</script> のような
// 文字列を入力し、他のユーザーのブラウザで実行させる攻撃。
//
// 【エスケープの仕組み】
//   入力          →  出力
//   ────────────────────────
//   <script>      →  &lt;script&gt;
//   "onclick"     →  &quot;onclick&quot;
//   &             →  &amp;
//
// 【引数】
// @param {string} text - エスケープする文字列
//
// 【戻り値】
// @returns {string} エスケープされた安全な文字列
//
// 【使用例】
//   escapeHtml("<script>alert('危険')</script>")
//   // => "&lt;script&gt;alert('危険')&lt;/script&gt;"
//
export function escapeHtml(text) {
  // null/undefined チェック
  if (!text) return ''

  // テクニック: DOM要素を使ってエスケープ
  // textContent に設定すると自動でエスケープされ、
  // innerHTML で取り出すとエスケープ済み文字列が得られる
  const div = document.createElement('div')
  div.textContent = text
  return div.innerHTML
}

// ------------------------------------------
// CSRFトークンを取得
// ------------------------------------------
// 【何をする関数？】
// RailsのCSRF保護トークンをHTMLから取得。
// POSTリクエストなどで必要。
//
// 【CSRF（Cross-Site Request Forgery）とは？】
// 悪意あるサイトがユーザーになりすましてリクエストを送る攻撃。
// Railsは各リクエストにトークンを要求して防御している。
//
// 【トークンの場所】
// app/views/layouts/application.html.erb の
// <%= csrf_meta_tags %> で以下のメタタグが出力される:
//   <meta name="csrf-token" content="ランダムな文字列">
//
// 【戻り値】
// @returns {string|null} CSRFトークン（存在しない場合はnull）
//
export function getCsrfToken() {
  // ?.（オプショナルチェイニング）:
  // メタタグが存在しない場合でもエラーにならない
  return document.querySelector('meta[name="csrf-token"]')?.content
}

// ------------------------------------------
// JSON APIリクエストを送信
// ------------------------------------------
// 【何をする関数？】
// JSON形式のAPIリクエストを簡単に送信するためのラッパー関数。
// CSRFトークンやContent-Typeの設定を自動で行う。
//
// 【なぜこの関数が必要？】
// fetch() を直接使うと、毎回以下の設定が必要:
// - Content-Type: application/json
// - Accept: application/json
// - X-CSRF-Token: <token>
//
// この関数を使えば、これらを自動設定してくれる。
//
// 【引数】
// @param {string} url - リクエストURL
// @param {Object} options - fetch オプション（method, body など）
//
// 【戻り値】
// @returns {Promise<Response>} fetchのレスポンス
//
// 【使用例】
//   // GETリクエスト
//   const response = await fetchJson('/api/posts')
//   const data = await response.json()
//
//   // POSTリクエスト
//   const response = await fetchJson('/api/posts', {
//     method: 'POST',
//     body: JSON.stringify({ title: '新しい投稿' })
//   })
//
export async function fetchJson(url, options = {}) {
  // デフォルトのヘッダー設定
  const defaultHeaders = {
    'Content-Type': 'application/json',  // 送信形式
    'Accept': 'application/json',        // 受信形式
    'X-CSRF-Token': getCsrfToken()       // CSRF保護トークン
  }

  // fetch実行（デフォルトヘッダーと渡されたオプションをマージ）
  return fetch(url, {
    ...options,                           // method, body などをコピー
    headers: {
      ...defaultHeaders,                  // デフォルトヘッダー
      ...options.headers                  // 追加のヘッダー（上書き可能）
    }
  })
}
