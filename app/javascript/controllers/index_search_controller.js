// app/javascript/controllers/index_search_controller.js
// ==========================================
// 投稿一覧検索コントローラー
// ==========================================
//
// 【このコントローラーの役割】
// トップページの検索フォームで、既存の投稿（動画）を検索。
// インクリメンタルサーチ（入力するたびに結果が更新される）を実現。
//
// 【youtube_search_controller との違い】
// - youtube_search: YouTube APIで新規動画を検索
// - index_search: DBに登録済みの動画（アクションプランがあるもの）を検索
//
// 【HTML側の使い方】
//   <div data-controller="index-search"
//        data-index-search-search-url-value="/posts/search"
//        data-index-search-min-length-value="2">
//
//     <input type="text"
//            data-index-search-target="input"
//            data-action="input->index-search#handleInput
//                         keydown->index-search#handleKeydown">
//
//     <div data-index-search-target="results" class="hidden">
//       <!-- 検索結果がここに挿入される -->
//     </div>
//   </div>
//
// 【インクリメンタルサーチとは？】
// 入力するたびにリアルタイムで検索結果が更新される検索方式。
// Googleの検索窓のような動作。デバウンス（遅延）を入れて
// 過度なリクエストを防いでいる。
//

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // ------------------------------------------
  // Targets & Values
  // ------------------------------------------
  static targets = ["input", "results"]
  static values = {
    searchUrl: String,                          // 検索APIのURL
    minLength: { type: Number, default: 2 }     // 検索を開始する最小文字数
  }

  // ------------------------------------------
  // connect: 初期化
  // ------------------------------------------
  connect() {
    this.timeout = null      // デバウンス用タイマー
    this.selectedIndex = -1  // キーボードナビゲーション用

    // クリック外で結果を閉じる
    this.handleClickOutside = this.handleClickOutside.bind(this)
    document.addEventListener("click", this.handleClickOutside)
  }

  // ------------------------------------------
  // disconnect: クリーンアップ
  // ------------------------------------------
  disconnect() {
    document.removeEventListener("click", this.handleClickOutside)
  }

  // ------------------------------------------
  // handleInput: 入力ハンドラー
  // ------------------------------------------
  // 【何をするメソッド？】
  // 入力値が変わるたびに呼ばれる。
  // デバウンス（300ms遅延）を入れて検索を実行。
  //
  // 【デバウンスとは？】
  // 連続した入力があっても、最後の入力から一定時間経ってから
  // 処理を実行する仕組み。サーバー負荷軽減のため。
  //
  handleInput() {
    // 既存のタイマーをキャンセル
    clearTimeout(this.timeout)

    const value = this.inputTarget.value.trim()

    // 空または文字数不足の場合は結果を隠す
    if (!value || value.length < this.minLengthValue) {
      this.hideResults()
      return
    }

    // 検索を実行（300ms遅延）
    this.timeout = setTimeout(() => {
      this.fetchResults(value)
    }, 300)
  }

  // ------------------------------------------
  // handleKeydown: キーボードナビゲーション
  // ------------------------------------------
  // 【何をするメソッド？】
  // 矢印キーで検索結果を選択、Enterで決定、Escで閉じる。
  //
  handleKeydown(event) {
    const items = this.resultsTarget.querySelectorAll("[data-index]")

    switch (event.key) {
      case "ArrowDown":
        event.preventDefault()  // ページスクロールを防ぐ
        this.selectedIndex = Math.min(this.selectedIndex + 1, items.length - 1)
        this.updateSelection(items)
        break

      case "ArrowUp":
        event.preventDefault()
        this.selectedIndex = Math.max(this.selectedIndex - 1, -1)
        this.updateSelection(items)
        break

      case "Enter":
        event.preventDefault()
        // 選択中のアイテムをクリック
        if (this.selectedIndex >= 0 && items[this.selectedIndex]) {
          items[this.selectedIndex].click()
        }
        break

      case "Escape":
        this.hideResults()
        this.inputTarget.blur()  // フォーカスを外す
        break
    }
  }

  // ------------------------------------------
  // updateSelection: 選択状態の更新
  // ------------------------------------------
  // 【何をするメソッド？】
  // 選択中のアイテムにハイライトを付ける。
  //
  updateSelection(items) {
    items.forEach((item, i) => {
      if (i === this.selectedIndex) {
        item.classList.add("bg-gray-100")
      } else {
        item.classList.remove("bg-gray-100")
      }
    })
  }

  // ------------------------------------------
  // fetchResults: 検索結果を取得
  // ------------------------------------------
  // 【何をするメソッド？】
  // サーバーに検索リクエストを送り、結果を表示。
  //
  async fetchResults(query) {
    try {
      // ローディング表示
      this.resultsTarget.innerHTML = `
        <div class="p-4 text-center text-gray-500 text-sm">
          <div class="inline-block w-4 h-4 border-2 border-gray-300 border-t-gray-600 rounded-full animate-spin mr-2"></div>
          検索中...
        </div>
      `
      this.showResults()

      // 検索APIを呼び出し
      // encodeURIComponent: 日本語や特殊文字をURLに使える形式に変換
      const response = await fetch(`${this.searchUrlValue}?q=${encodeURIComponent(query)}`, {
        headers: { "Accept": "application/json" }
      })

      if (!response.ok) throw new Error("Search failed")

      const posts = await response.json()
      this.renderResults(posts)
    } catch (error) {
      console.error("Search error:", error)
      this.resultsTarget.innerHTML = '<p class="text-center text-gray-500 p-4 text-sm">検索に失敗しました</p>'
    }
  }

  // ------------------------------------------
  // renderResults: 検索結果を描画
  // ------------------------------------------
  // 【何をするメソッド？】
  // 検索結果をHTMLとして描画。
  //
  renderResults(posts) {
    if (posts.length === 0) {
      this.resultsTarget.innerHTML = '<p class="text-center text-gray-500 p-4 text-sm">該当する投稿が見つかりません</p>'
      return
    }

    // 各投稿をHTMLに変換
    const html = posts.map((post, index) => `
      <a href="${post.url}"
         class="flex items-start gap-3 p-3 hover:bg-gray-50 transition-colors text-left border-b border-gray-100 last:border-b-0"
         data-index="${index}">
        <img src="${post.thumbnail_url}" alt="" class="w-20 h-12 object-cover rounded flex-shrink-0">
        <div class="flex-1 min-w-0">
          <p class="text-sm font-medium text-gray-900 line-clamp-2">${this.escapeHtml(post.title)}</p>
          <div class="flex items-center gap-2 mt-0.5">
            <p class="text-xs text-gray-500 truncate">${this.escapeHtml(post.channel_name)}</p>
            <span class="text-xs text-gray-400">${post.entry_count}件のアクションプラン</span>
          </div>
        </div>
      </a>
    `).join("")

    this.resultsTarget.innerHTML = html
    this.selectedIndex = -1  // 選択をリセット
  }

  // ------------------------------------------
  // 表示/非表示メソッド
  // ------------------------------------------
  showResults() {
    this.resultsTarget.classList.remove("hidden")
  }

  hideResults() {
    this.resultsTarget.classList.add("hidden")
    this.resultsTarget.innerHTML = ""
    this.selectedIndex = -1
  }

  // ------------------------------------------
  // handleClickOutside: 外側クリックで閉じる
  // ------------------------------------------
  handleClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.hideResults()
    }
  }

  // ------------------------------------------
  // escapeHtml: XSS対策のHTMLエスケープ
  // ------------------------------------------
  escapeHtml(text) {
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  }
}
