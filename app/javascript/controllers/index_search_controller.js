// 投稿一覧検索コントローラー
// DBに登録済みの動画をインクリメンタルサーチで検索

import { Controller } from "@hotwired/stimulus"                // Stimulusコントローラー基底クラス

export default class extends Controller {
  static targets = ["input", "results"]                        // input: 検索欄, results: 結果表示領域
  static values = {
    searchUrl: String,                                         // 検索APIのURL
    minLength: { type: Number, default: 2 }                    // 検索開始の最小文字数
  }

  // 初期化
  connect() {
    this.timeout = null                                        // デバウンス用タイマー
    this.selectedIndex = -1                                    // キーボード選択のインデックス
    this.handleClickOutside = this.handleClickOutside.bind(this)
    document.addEventListener("click", this.handleClickOutside)
  }

  // クリーンアップ
  disconnect() {
    document.removeEventListener("click", this.handleClickOutside)
  }

  // 入力時のハンドラー（デバウンス300ms）
  handleInput() {
    clearTimeout(this.timeout)                                 // 既存タイマーをキャンセル
    const value = this.inputTarget.value.trim()

    if (!value || value.length < this.minLengthValue) {        // 文字数不足
      this.hideResults()
      return
    }

    this.timeout = setTimeout(() => {                          // 300ms後に検索実行
      this.fetchResults(value)
    }, 300)
  }

  // キーボードナビゲーション
  handleKeydown(event) {
    const items = this.resultsTarget.querySelectorAll("[data-index]")

    switch (event.key) {
      case "ArrowDown":
        event.preventDefault()                                 // ページスクロール防止
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
        if (this.selectedIndex >= 0 && items[this.selectedIndex]) {
          items[this.selectedIndex].click()                    // 選択中のアイテムをクリック
        }
        break
      case "Escape":
        this.hideResults()
        this.inputTarget.blur()                                // フォーカスを外す
        break
    }
  }

  // 選択状態のハイライト更新
  updateSelection(items) {
    items.forEach((item, i) => {
      if (i === this.selectedIndex) {
        item.classList.add("bg-gray-100")
      } else {
        item.classList.remove("bg-gray-100")
      }
    })
  }

  // サーバーに検索リクエストを送信
  async fetchResults(query) {
    try {
      this.resultsTarget.innerHTML = `
        <div class="p-4 text-center text-gray-500 text-sm">
          <div class="inline-block w-4 h-4 border-2 border-gray-300 border-t-gray-600 rounded-full animate-spin mr-2"></div>
          検索中...
        </div>
      `
      this.showResults()

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

  // 検索結果をHTMLとして描画
  renderResults(posts) {
    if (posts.length === 0) {
      this.resultsTarget.innerHTML = '<p class="text-center text-gray-500 p-4 text-sm">該当する投稿が見つかりません</p>'
      return
    }

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
    this.selectedIndex = -1                                    // 選択をリセット
  }

  // 結果を表示
  showResults() {
    this.resultsTarget.classList.remove("hidden")
  }

  // 結果を非表示
  hideResults() {
    this.resultsTarget.classList.add("hidden")
    this.resultsTarget.innerHTML = ""
    this.selectedIndex = -1
  }

  // 外側クリックで結果を閉じる
  handleClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.hideResults()
    }
  }

  // XSS対策のHTMLエスケープ
  escapeHtml(text) {
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  }
}
