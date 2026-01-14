// app/javascript/controllers/index_search_controller.js
import { Controller } from "@hotwired/stimulus"

// 投稿一覧用の統合検索コントローラー
// URL貼り付けまたはタイトル検索 → 動画選択で投稿を自動作成して遷移
export default class extends Controller {
  static targets = ["input", "results", "pasteButton"]
  static values = {
    youtubeUrl: String,
    findOrCreateUrl: { type: String, default: "/posts/find_or_create" },
    minLength: { type: Number, default: 2 }
  }

  connect() {
    this.timeout = null
    this.selectedIndex = -1

    // クリック外で結果を閉じる
    this.handleClickOutside = this.handleClickOutside.bind(this)
    document.addEventListener("click", this.handleClickOutside)

    // Clipboard APIが使えない場合はペーストボタンを非表示
    if (this.hasPasteButtonTarget && !navigator.clipboard) {
      this.pasteButtonTarget.classList.add("hidden")
    }
  }

  disconnect() {
    document.removeEventListener("click", this.handleClickOutside)
  }

  // 統合入力ハンドラー
  handleInput() {
    clearTimeout(this.timeout)
    const value = this.inputTarget.value.trim()

    if (!value) {
      this.hideResults()
      return
    }

    // YouTube URLかどうかを判定
    const videoId = this.extractVideoId(value)

    if (videoId) {
      // URL入力の場合 → 新規投稿ページへ遷移
      this.showUrlDetected(value)
    } else if (value.length >= this.minLengthValue) {
      // 検索クエリの場合 → YouTube検索
      this.timeout = setTimeout(() => {
        this.fetchResults(value)
      }, 300)
    } else {
      this.hideResults()
    }
  }

  // キーボードナビゲーション
  handleKeydown(event) {
    const items = this.resultsTarget.querySelectorAll("[data-index]")

    switch (event.key) {
      case "ArrowDown":
        event.preventDefault()
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
          items[this.selectedIndex].click()
        } else {
          // 選択なしでEnter → URLなら投稿作成
          const value = this.inputTarget.value.trim()
          const videoId = this.extractVideoId(value)
          if (videoId) {
            this.findOrCreatePost(value)
          }
        }
        break
      case "Escape":
        this.hideResults()
        this.inputTarget.blur()
        break
    }
  }

  updateSelection(items) {
    items.forEach((item, i) => {
      if (i === this.selectedIndex) {
        item.classList.add("bg-gray-100")
      } else {
        item.classList.remove("bg-gray-100")
      }
    })
  }

  // クリップボードから貼り付け
  async pasteFromClipboard() {
    try {
      const text = await navigator.clipboard.readText()
      if (text) {
        this.inputTarget.value = text.trim()
        this.inputTarget.focus()
        this.handleInput()
      }
    } catch (error) {
      // 権限がない場合やクリップボードが空の場合
      console.log("Clipboard read failed:", error.message)
      // ユーザーに入力を促す
      this.inputTarget.focus()
    }
  }

  // URL検出時の表示
  showUrlDetected(url) {
    const videoId = this.extractVideoId(url)
    const thumbnail = `https://img.youtube.com/vi/${videoId}/mqdefault.jpg`

    this.resultsTarget.innerHTML = `
      <button type="button"
              class="w-full flex items-center gap-3 p-3 hover:bg-gray-50 transition-colors text-left"
              data-action="click->index-search#selectUrl"
              data-url="${this.escapeHtml(url)}"
              data-index="0">
        <img src="${thumbnail}" alt="" class="w-20 h-12 object-cover rounded flex-shrink-0">
        <div class="flex-1">
          <p class="text-sm font-medium text-gray-900">この動画を開く</p>
          <p class="text-xs text-gray-500">Enterキーまたはクリックで移動</p>
        </div>
        <svg class="w-5 h-5 text-gray-400" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path stroke-linecap="round" stroke-linejoin="round" d="M14 5l7 7m0 0l-7 7m7-7H3"/>
        </svg>
      </button>
    `
    this.selectedIndex = 0
    this.showResults()
  }

  // YouTube検索結果を取得
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

      const response = await fetch(`${this.youtubeUrlValue}?q=${encodeURIComponent(query)}`, {
        headers: { "Accept": "application/json" }
      })

      if (!response.ok) throw new Error("Search failed")

      const videos = await response.json()
      this.renderResults(videos)
    } catch (error) {
      console.error("YouTube search error:", error)
      this.resultsTarget.innerHTML = '<p class="text-center text-gray-500 p-4 text-sm">検索に失敗しました</p>'
    }
  }

  // 検索結果を描画
  renderResults(videos) {
    if (videos.length === 0) {
      this.resultsTarget.innerHTML = '<p class="text-center text-gray-500 p-4 text-sm">動画が見つかりません</p>'
      return
    }

    const html = videos.map((video, index) => `
      <button type="button"
              class="w-full flex items-start gap-3 p-3 hover:bg-gray-50 transition-colors text-left border-b border-gray-100 last:border-b-0"
              data-action="click->index-search#selectVideo"
              data-url="${video.youtube_url}"
              data-index="${index}">
        <img src="${video.thumbnail_url}" alt="" class="w-20 h-12 object-cover rounded flex-shrink-0">
        <div class="flex-1 min-w-0">
          <p class="text-sm font-medium text-gray-900 line-clamp-2">${this.escapeHtml(video.title)}</p>
          <p class="text-xs text-gray-500 mt-0.5">${this.escapeHtml(video.channel_name)}</p>
        </div>
      </button>
    `).join("")

    this.resultsTarget.innerHTML = html
    this.selectedIndex = -1
  }

  // URL選択時
  selectUrl(event) {
    const url = event.currentTarget.dataset.url
    this.findOrCreatePost(url)
  }

  // 動画選択時
  selectVideo(event) {
    const url = event.currentTarget.dataset.url
    this.findOrCreatePost(url)
  }

  // 投稿を検索または作成して遷移
  async findOrCreatePost(youtubeUrl) {
    // ローディング表示
    this.resultsTarget.innerHTML = `
      <div class="p-4 text-center text-gray-500 text-sm">
        <div class="inline-block w-5 h-5 border-2 border-gray-300 border-t-orange-500 rounded-full animate-spin mr-2"></div>
        動画を読み込み中...
      </div>
    `

    try {
      const response = await fetch(this.findOrCreateUrlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content
        },
        body: JSON.stringify({ youtube_url: youtubeUrl })
      })

      const data = await response.json()
      console.log("find_or_create response:", data)

      if (data.success && data.url) {
        console.log("Navigating to:", data.url)
        // Turbo Driveを使用してナビゲーション（グローバルオブジェクト経由）
        if (window.Turbo) {
          console.log("Using Turbo.visit")
          window.Turbo.visit(data.url)
        } else {
          console.log("Using window.location.href")
          window.location.href = data.url
        }
      } else {
        console.error("Navigation failed:", data)
        this.resultsTarget.innerHTML = `
          <div class="p-4 text-center text-red-500 text-sm">
            ${data.error || "エラーが発生しました"}
          </div>
        `
      }
    } catch (error) {
      console.error("Find or create error:", error)
      this.resultsTarget.innerHTML = `
        <div class="p-4 text-center text-red-500 text-sm">
          エラーが発生しました: ${error.message}
        </div>
      `
    }
  }

  // URLからビデオIDを抽出
  extractVideoId(url) {
    const patterns = [
      /(?:youtube\.com\/watch\?v=|youtu\.be\/|youtube\.com\/embed\/)([a-zA-Z0-9_-]{11})/,
      /^([a-zA-Z0-9_-]{11})$/
    ]

    for (const pattern of patterns) {
      const match = url.match(pattern)
      if (match) return match[1]
    }
    return null
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

  // クリック外で閉じる
  handleClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.hideResults()
    }
  }

  // HTMLエスケープ
  escapeHtml(text) {
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  }
}
