// app/javascript/controllers/youtube_search_controller.js
import { Controller } from "@hotwired/stimulus"

// 統合YouTube検索コントローラー
// URL貼り付けとタイトル検索を1つのフィールドで処理
export default class extends Controller {
  static targets = ["input", "results", "urlField", "preview", "thumbnail", "title", "channel"]
  static values = {
    url: String,
    minLength: { type: Number, default: 2 }
  }

  connect() {
    this.timeout = null
    this.selectedVideoUrl = null

    // 既存のURLがあればプレビューを表示
    const initialUrl = (this.hasUrlFieldTarget && this.urlFieldTarget.value) ||
                       (this.hasInputTarget && this.inputTarget.value)
    if (initialUrl && this.extractVideoId(initialUrl)) {
      this.showPreviewForUrl(initialUrl)
      if (this.hasUrlFieldTarget) {
        this.urlFieldTarget.value = initialUrl
      }
    }
  }

  // 統合入力ハンドラー - URLか検索クエリかを自動判定
  handleInput() {
    clearTimeout(this.timeout)
    const value = this.inputTarget.value.trim()

    if (!value) {
      this.hideResults()
      this.hidePreview()
      this.clearUrlField()
      return
    }

    // YouTube URLかどうかを判定
    const videoId = this.extractVideoId(value)

    if (videoId) {
      // URL入力の場合 → プレビュー表示
      this.hideResults()
      this.showPreviewForUrl(value)
      this.setUrlField(value)
    } else if (value.length >= this.minLengthValue) {
      // 検索クエリの場合 → 検索実行（遅延）
      this.hidePreview()
      this.clearUrlField()
      this.timeout = setTimeout(() => {
        this.fetchResults(value)
      }, 300)
    } else {
      this.hideResults()
    }
  }

  // URL入力時にプレビュー表示
  showPreviewForUrl(url, fetchInfo = true) {
    const videoId = this.extractVideoId(url)
    if (!videoId) {
      this.hidePreview()
      return
    }

    // サムネイルプレビューを表示
    if (this.hasPreviewTarget && this.hasThumbnailTarget) {
      this.thumbnailTarget.src = `https://img.youtube.com/vi/${videoId}/hqdefault.jpg`
      this.previewTarget.classList.remove("hidden")

      // タイトルとチャンネル名は読み込み中
      if (this.hasTitleTarget) this.titleTarget.textContent = "読み込み中..."
      if (this.hasChannelTarget) this.channelTarget.textContent = ""

      this.selectedVideoUrl = url

      // 動画情報を取得
      if (fetchInfo && this.urlValue) {
        this.fetchVideoInfoForUrl(videoId)
      }
    }
  }

  // URLから動画情報を取得
  async fetchVideoInfoForUrl(videoId) {
    try {
      // video IDで検索して動画情報を取得
      const response = await fetch(`${this.urlValue}?q=${encodeURIComponent(videoId)}`, {
        headers: { "Accept": "application/json" }
      })

      if (!response.ok) throw new Error("Fetch failed")

      const videos = await response.json()
      if (videos.length > 0) {
        const video = videos[0]
        if (this.hasTitleTarget) {
          this.titleTarget.textContent = video.title || "動画"
        }
        if (this.hasChannelTarget) {
          this.channelTarget.textContent = video.channel_name || ""
        }
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

  // 検索結果を取得
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

  // 動画を選択
  selectVideo(event) {
    const button = event.currentTarget
    const url = button.dataset.url
    const title = button.dataset.title
    const channel = button.dataset.channel
    const thumbnail = button.dataset.thumbnail

    // 入力フィールドを更新
    this.inputTarget.value = url
    this.setUrlField(url)
    this.selectedVideoUrl = url

    // プレビューを更新
    if (this.hasPreviewTarget) {
      if (this.hasThumbnailTarget && thumbnail) {
        this.thumbnailTarget.src = thumbnail
      }
      if (this.hasTitleTarget) {
        this.titleTarget.textContent = title || ""
      }
      if (this.hasChannelTarget) {
        this.channelTarget.textContent = channel || ""
      }
      this.previewTarget.classList.remove("hidden")
    }

    // 検索結果を非表示
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

  // URLフィールドを設定
  setUrlField(url) {
    if (this.hasUrlFieldTarget) {
      this.urlFieldTarget.value = url
    }
  }

  // URLフィールドをクリア
  clearUrlField() {
    if (this.hasUrlFieldTarget) {
      this.urlFieldTarget.value = ""
    }
  }

  // プレビューを非表示
  hidePreview() {
    if (this.hasPreviewTarget) {
      this.previewTarget.classList.add("hidden")
    }
    this.selectedVideoUrl = null
  }

  // 検索結果を非表示
  hideResults() {
    if (this.hasResultsTarget) {
      this.resultsTarget.classList.add("hidden")
      this.resultsTarget.innerHTML = ""
    }
  }

  // 検索結果を表示
  showResults() {
    if (this.hasResultsTarget) {
      this.resultsTarget.classList.remove("hidden")
    }
  }

  // HTMLエスケープ
  escapeHtml(text) {
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  }

  // クリック外で結果を閉じる
  clickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.hideResults()
    }
  }

  // 旧メソッド（互換性のため）
  toggleMode() {}
  search() { this.handleInput() }
  fetchVideoInfo() { this.handleInput() }
}
