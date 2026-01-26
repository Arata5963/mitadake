// app/javascript/application.js
// ==========================================
// JavaScriptアプリケーションのエントリーポイント
// ==========================================
//
// 【このファイルの役割】
// Railsアプリ全体で使用するJavaScriptの読み込み起点。
// app/views/layouts/application.html.erb の javascript_importmap_tags で
// 自動的に読み込まれる。
//
// 【Importmapとは？】
// Rails 7で採用されたJavaScript管理方式。
// config/importmap.rb でライブラリの読み込み先を定義する。
// webpackやesbuildを使わず、ブラウザのネイティブ機能で
// モジュールを読み込む仕組み。
//
// 【読み込まれるもの】
// 1. @hotwired/turbo-rails: Turbo Drive/Frames/Streams
//    - ページ遷移を高速化（SPAライクな体験）
//    - フォーム送信のAJAX化
//    - 部分的なページ更新
//
// 2. controllers: Stimulusコントローラー
//    - app/javascript/controllers/ 以下の全ファイル
//    - DOM操作、イベントハンドリング
//

// Turbo Driveの読み込み（ページ遷移の高速化）
import "@hotwired/turbo-rails"

// Stimulusコントローラーの読み込み
import "controllers"

// ------------------------------------------
// sessionStorageからフラッシュメッセージを表示
// ------------------------------------------
// 達成処理など、ページリロードを伴う操作で
// フラッシュメッセージを保持するための仕組み
//
function showPendingFlash() {
  const pendingFlash = sessionStorage.getItem('pendingFlash')
  if (!pendingFlash) return

  sessionStorage.removeItem('pendingFlash')

  try {
    const { type, message } = JSON.parse(pendingFlash)
    const container = document.getElementById('flash-messages')
    if (!container) return

    const styles = type === 'notice' || type === 'success'
      ? 'bg-green-50 border-green-500 text-green-700'
      : 'bg-red-50 border-red-500 text-red-700'

    const iconColor = type === 'notice' || type === 'success' ? 'text-green-500' : 'text-red-500'
    const iconPath = type === 'notice' || type === 'success'
      ? 'M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z'
      : 'M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z'

    const flashHtml = `
      <div class="${styles} border-l-4 rounded-r-lg px-4 py-3 shadow-lg animate-fade-in"
           data-controller="flash"
           data-flash-remove-after-value="5000">
        <div class="flex items-start gap-3">
          <div class="flex-shrink-0">
            <svg class="h-5 w-5 ${iconColor}" viewBox="0 0 20 20" fill="currentColor">
              <path fill-rule="evenodd" d="${iconPath}" clip-rule="evenodd" />
            </svg>
          </div>
          <p class="text-sm font-medium flex-1">${message}</p>
          <button type="button"
                  data-action="click->flash#remove"
                  class="flex-shrink-0 opacity-50 hover:opacity-100 transition-opacity">
            <svg class="h-4 w-4" viewBox="0 0 20 20" fill="currentColor">
              <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd" />
            </svg>
          </button>
        </div>
      </div>
    `
    container.insertAdjacentHTML('beforeend', flashHtml)
  } catch (e) {
    console.error('Failed to show pending flash:', e)
  }
}

// Turboのページロード完了時にフラッシュを表示
document.addEventListener('turbo:load', showPendingFlash)
// 初回ロード時にも対応
document.addEventListener('DOMContentLoaded', showPendingFlash)
