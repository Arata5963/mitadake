// app/javascript/controllers/youtube_search_controller.js
// ==========================================
// YouTube統合検索コントローラー
// ==========================================
//
// 【このコントローラーの役割】
// YouTube URLの貼り付けとタイトル検索を1つの入力欄で処理。
// 入力された値がURLなのかキーワードなのかを自動判定する。
//
// 【index_search_controller との違い】
// - youtube_search: YouTube APIで新規動画を検索
// - index_search: DBに登録済みの動画を検索
//
// 【動作パターン】
// 1. YouTube URLを入力
//    → URLとして認識し、動画のプレビューを表示
//
// 2. キーワードを入力
//    → YouTube APIで検索し、結果一覧を表示
//    → 動画を選択するとURLフィールドに設定
//
// 【HTML側の使い方】
//   <div data-controller="youtube-search"
//        data-youtube-search-url-value="/youtube/search"
//        data-youtube-search-min-length-value="2">
//
//     <input type="text"
//            data-youtube-search-target="input"
//            data-action="input->youtube-search#handleInput">
//
//     <!-- 検索結果 -->
//     <div data-youtube-search-target="results" class="hidden"></div>
//
//     <!-- プレビュー（URL入力時に表示） -->
//     <div data-youtube-search-target="preview" class="hidden">
//       <img data-youtube-search-target="thumbnail">
//       <p data-youtube-search-target="title"></p>
//       <p data-youtube-search-target="channel"></p>
//     </div>
//
//     <!-- 実際のフォームに送信するURLフィールド -->
//     <input type="hidden" data-youtube-search-target="urlField">
//   </div>
//

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // ------------------------------------------
  // Targets & Values
  // ------------------------------------------
  static targets = ["input", "results", "urlField", "preview", "thumbnail", "title", "channel"]
  static values = {
    url: String,                              // YouTube検索APIのURL
    minLength: { type: Number, default: 2 }   // 検索を開始する最小文字数
  }

  // ------------------------------------------
  // connect: 初期化
  // ------------------------------------------
  connect() {
    this.timeout = null
    this.selectedVideoUrl = null

    // 既存のURLがあればプレビューを表示（編集モード）
    const initialUrl = (this.hasUrlFieldTarget && this.urlFieldTarget.value) ||
                       (this.hasInputTarget && this.inputTarget.value)
    if (initialUrl && this.extractVideoId(initialUrl)) {
      this.showPreviewForUrl(initialUrl)
      if (this.hasUrlFieldTarget) {
        this.urlFieldTarget.value = initialUrl
      }
    }
  }

  // ------------------------------------------
  // handleInput: 統合入力ハンドラー
  // ------------------------------------------
  // 【何をするメソッド？】
  // 入力値がURLかキーワードかを自動判定して処理を分岐。
  //
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
      // ------------------------------------------
      // URL入力の場合
      // ------------------------------------------
      // プレビューを表示してURLフィールドに設定
      this.hideResults()
      this.showPreviewForUrl(value)
      this.setUrlField(value)
    } else if (value.length >= this.minLengthValue) {
      // ------------------------------------------
      // キーワード入力の場合
      // ------------------------------------------
      // YouTube APIで検索（デバウンス付き）
      this.hidePreview()
      this.clearUrlField()
      this.timeout = setTimeout(() => {
        this.fetchResults(value)
      }, 300)
    } else {
      this.hideResults()
    }
  }

  // ------------------------------------------
  // showPreviewForUrl: URL入力時のプレビュー表示
  // ------------------------------------------
  // 【何をするメソッド？】
  // YouTube URLが入力された時に動画のサムネイルとタイトルをプレビュー表示。
  //
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

      // 動画情報を取得してタイトルを更新
      if (fetchInfo && this.urlValue) {
        this.fetchVideoInfoForUrl(videoId)
      }
    }
  }

  // ------------------------------------------
  // fetchVideoInfoForUrl: URLから動画情報を取得
  // ------------------------------------------
  // 【何をするメソッド？】
  // 動画IDでAPIを叩いてタイトル・チャンネル名を取得。
  //
  async fetchVideoInfoForUrl(videoId) {
    try {
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

  // ------------------------------------------
  // extractVideoId: URLから動画IDを抽出
  // ------------------------------------------
  // 【何をするメソッド？】
  // 各種形式のYouTube URLから11文字の動画IDを抽出。
  //
  // 対応形式:
  // - https://www.youtube.com/watch?v=xxxxx
  // - https://youtu.be/xxxxx
  // - https://youtube.com/embed/xxxxx
  // - xxxxx（動画IDそのまま）
  //
  extractVideoId(url) {
    const patterns = [
      /(?:youtube\.com\/watch\?v=|youtu\.be\/|youtube\.com\/embed\/)([a-zA-Z0-9_-]{11})/,
      /^([a-zA-Z0-9_-]{11})$/  // IDのみ（11文字）
    ]

    for (const pattern of patterns) {
      const match = url.match(pattern)
      if (match) return match[1]
    }
    return null
  }

  // ------------------------------------------
  // fetchResults: キーワード検索結果を取得
  // ------------------------------------------
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

  // ------------------------------------------
  // renderResults: 検索結果を描画
  // ------------------------------------------
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

  // ------------------------------------------
  // selectVideo: 動画を選択
  // ------------------------------------------
  // 【何をするメソッド？】
  // 検索結果から動画をクリックした時に呼ばれる。
  // 入力欄とプレビューを更新し、URLフィールドに値を設定。
  //
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

  // ------------------------------------------
  // clearSelection: 選択をクリア
  // ------------------------------------------
  clearSelection() {
    this.inputTarget.value = ""
    this.clearUrlField()
    this.hidePreview()
    this.hideResults()
    this.selectedVideoUrl = null
    this.inputTarget.focus()
  }

  // ------------------------------------------
  // URLフィールド操作
  // ------------------------------------------
  setUrlField(url) {
    if (this.hasUrlFieldTarget) {
      this.urlFieldTarget.value = url
    }
  }

  clearUrlField() {
    if (this.hasUrlFieldTarget) {
      this.urlFieldTarget.value = ""
    }
  }

  // ------------------------------------------
  // 表示/非表示
  // ------------------------------------------
  hidePreview() {
    if (this.hasPreviewTarget) {
      this.previewTarget.classList.add("hidden")
    }
    this.selectedVideoUrl = null
  }

  hideResults() {
    if (this.hasResultsTarget) {
      this.resultsTarget.classList.add("hidden")
      this.resultsTarget.innerHTML = ""
    }
  }

  showResults() {
    if (this.hasResultsTarget) {
      this.resultsTarget.classList.remove("hidden")
    }
  }

  // ------------------------------------------
  // escapeHtml: XSS対策
  // ------------------------------------------
  escapeHtml(text) {
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  }

  // 外側クリックで結果を閉じる
  clickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.hideResults()
    }
  }

  // 旧メソッド（互換性のため維持）
  toggleMode() {}
  search() { this.handleInput() }
  fetchVideoInfo() { this.handleInput() }
}
