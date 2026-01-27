// YouTube統合検索コントローラー
// YouTube URLの貼り付けとキーワード検索を1つの入力欄で処理

import { Controller } from "@hotwired/stimulus"                // Stimulusコントローラー基底クラス

export default class extends Controller {
  static targets = ["input", "results", "urlField", "preview", "thumbnail", "title", "channel"]
  static values = {
    url: String,                                               // YouTube検索APIのURL
    minLength: { type: Number, default: 2 }                    // 検索開始の最小文字数
  }

  // 初期化（既存URLがあればプレビュー表示）
  connect() {
    this.timeout = null
    this.selectedVideoUrl = null

    const initialUrl = (this.hasUrlFieldTarget && this.urlFieldTarget.value) ||
                       (this.hasInputTarget && this.inputTarget.value)
    if (initialUrl && this.extractVideoId(initialUrl)) {
      this.showPreviewForUrl(initialUrl)
      if (this.hasUrlFieldTarget) {
        this.urlFieldTarget.value = initialUrl
      }
    }
  }

  // 入力値がURLかキーワードかを自動判定して処理
  handleInput() {
    clearTimeout(this.timeout)
    const value = this.inputTarget.value.trim()

    if (!value) {
      this.hideResults()
      this.hidePreview()
      this.clearUrlField()
      return
    }

    const videoId = this.extractVideoId(value)                 // URL判定

    if (videoId) {                                             // URL入力の場合
      this.hideResults()
      this.showPreviewForUrl(value)
      this.setUrlField(value)
    } else if (value.length >= this.minLengthValue) {          // キーワード入力の場合
      this.hidePreview()
      this.clearUrlField()
      this.timeout = setTimeout(() => {
        this.fetchResults(value)
      }, 300)
    } else {
      this.hideResults()
    }
  }

  // URL入力時のプレビュー表示
  showPreviewForUrl(url, fetchInfo = true) {
    const videoId = this.extractVideoId(url)
    if (!videoId) {
      this.hidePreview()
      return
    }

    if (this.hasPreviewTarget && this.hasThumbnailTarget) {
      this.thumbnailTarget.src = `https://img.youtube.com/vi/${videoId}/hqdefault.jpg`
      this.previewTarget.classList.remove("hidden")
      if (this.hasTitleTarget) this.titleTarget.textContent = "読み込み中..."
      if (this.hasChannelTarget) this.channelTarget.textContent = ""
      this.selectedVideoUrl = url

      if (fetchInfo && this.urlValue) {                        // タイトル・チャンネル名を取得
        this.fetchVideoInfoForUrl(videoId)
      }
    }
  }

  // URLから動画情報を取得
  async fetchVideoInfoForUrl(videoId) {
    try {
      const response = await fetch(`${this.urlValue}?q=${encodeURIComponent(videoId)}`, {
        headers: { "Accept": "application/json" }
      })

      if (!response.ok) throw new Error("Fetch failed")

      const videos = await response.json()
      if (videos.length > 0) {
        const video = videos[0]
        if (this.hasTitleTarget) this.titleTarget.textContent = video.title || "動画"
        if (this.hasChannelTarget) this.channelTarget.textContent = video.channel_name || ""
      } else {
        if (this.hasTitleTarget) this.titleTarget.textContent = "動画"
        if (this.hasChannelTarget) this.channelTarget.textContent = ""
      }
    } catch (error) {
      console.error("Video info fetch error:", error)
      if (this.hasTitleTarget) this.titleTarget.textContent = "動画"
      if (this.hasChannelTarget) this.channelTarget.textContent = ""
    }
  }

  // URLから動画IDを抽出
  extractVideoId(url) {
    const patterns = [
      /(?:youtube\.com\/watch\?v=|youtu\.be\/|youtube\.com\/embed\/)([a-zA-Z0-9_-]{11})/,
      /^([a-zA-Z0-9_-]{11})$/                                  // IDのみ（11文字）
    ]

    for (const pattern of patterns) {
      const match = url.match(pattern)
      if (match) return match[1]
    }
    return null
  }

  // キーワード検索結果を取得
  async fetchResults(query) {
    try {
      const response = await fetch(`${this.urlValue}?q=${encodeURIComponent(query)}`, {
        headers: { "Accept": "application/json" }
      })

      if (!response.ok) throw new Error("Search failed")

      const videos = await response.json()
      this.renderResults(videos)
    } catch (error) {
      console.error("YouTube search error:", error)
      this.resultsTarget.innerHTML = '<p class="text-center text-gray-500 py-4">検索に失敗しました</p>'
      this.showResults()
    }
  }

  // 検索結果を描画
  renderResults(videos) {
    if (videos.length === 0) {
      this.resultsTarget.innerHTML = '<p class="text-center text-gray-500 py-4">動画が見つかりません</p>'
      this.showResults()
      return
    }

    const html = videos.map(video => `
      <button type="button"
              class="w-full flex items-start gap-3 p-3 hover:bg-gray-50 rounded-lg transition-colors text-left"
              data-action="click->youtube-search#selectVideo"
              data-url="${video.youtube_url}"
              data-title="${this.escapeHtml(video.title)}"
              data-channel="${this.escapeHtml(video.channel_name)}"
              data-thumbnail="${video.thumbnail_url}">
        <img src="${video.thumbnail_url}" alt="" class="w-24 h-14 object-cover rounded flex-shrink-0">
        <div class="flex-1 min-w-0">
          <p class="text-sm font-medium text-gray-900 line-clamp-2">${this.escapeHtml(video.title)}</p>
          <p class="text-xs text-gray-500 mt-0.5">${this.escapeHtml(video.channel_name)}</p>
        </div>
      </button>
    `).join("")

    this.resultsTarget.innerHTML = html
    this.showResults()
  }

  // 検索結果から動画を選択
  selectVideo(event) {
    const button = event.currentTarget
    const url = button.dataset.url
    const title = button.dataset.title
    const channel = button.dataset.channel
    const thumbnail = button.dataset.thumbnail

    this.inputTarget.value = url                               // 入力欄を更新
    this.setUrlField(url)
    this.selectedVideoUrl = url

    if (this.hasPreviewTarget) {                               // プレビューを更新
      if (this.hasThumbnailTarget && thumbnail) this.thumbnailTarget.src = thumbnail
      if (this.hasTitleTarget) this.titleTarget.textContent = title || ""
      if (this.hasChannelTarget) this.channelTarget.textContent = channel || ""
      this.previewTarget.classList.remove("hidden")
    }

    this.hideResults()
  }

  // 選択をクリア
  clearSelection() {
    this.inputTarget.value = ""
    this.clearUrlField()
    this.hidePreview()
    this.hideResults()
    this.selectedVideoUrl = null
    this.inputTarget.focus()
  }

  // URLフィールド操作
  setUrlField(url) {
    if (this.hasUrlFieldTarget) this.urlFieldTarget.value = url
  }

  clearUrlField() {
    if (this.hasUrlFieldTarget) this.urlFieldTarget.value = ""
  }

  // 表示/非表示
  hidePreview() {
    if (this.hasPreviewTarget) this.previewTarget.classList.add("hidden")
    this.selectedVideoUrl = null
  }

  hideResults() {
    if (this.hasResultsTarget) {
      this.resultsTarget.classList.add("hidden")
      this.resultsTarget.innerHTML = ""
    }
  }

  showResults() {
    if (this.hasResultsTarget) this.resultsTarget.classList.remove("hidden")
  }

  // XSS対策
  escapeHtml(text) {
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  }

  // 外側クリックで結果を閉じる
  clickOutside(event) {
    if (!this.element.contains(event.target)) this.hideResults()
  }
}
