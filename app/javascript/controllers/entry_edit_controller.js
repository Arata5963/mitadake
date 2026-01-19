// app/javascript/controllers/entry_edit_controller.js
import { Controller } from "@hotwired/stimulus"

// アクションプラン編集コントローラー（新規投稿と同じUI）
export default class extends Controller {
  static targets = [
    "input", "results",
    "preview", "previewThumbnail", "previewTitle", "previewChannel",
    "actionPlanInput", "inputWrapper", "submitButton",
    "previewCard", "previewImage", "previewText",
    "fileInput", "uploadPlaceholder", "clearImageButton"
  ]
  static values = {
    youtubeUrl: String,
    updateUrl: String,
    currentPostId: Number,
    currentVideoId: String,
    currentVideoTitle: String,
    currentVideoChannel: String,
    currentVideoUrl: String,
    currentThumbnail: String,
    hasCustomThumbnail: Boolean,
    redirectUrl: String,
    minLength: { type: Number, default: 2 }
  }

  connect() {
    console.log("entry-edit controller connected")

    this.timeout = null
    this.selectedIndex = -1
    this.thumbnailData = null
    this.thumbnailCleared = false
    this.videoChanged = false

    // 選択中の動画情報（初期値は現在の動画）
    this.selectedVideo = {
      postId: this.currentPostIdValue,
      videoId: this.currentVideoIdValue,
      title: this.currentVideoTitleValue,
      channel: this.currentVideoChannelValue,
      url: this.currentVideoUrlValue,
      thumbnail: this.currentThumbnailValue
    }

    // 初期値として現在の動画URLを表示
    if (this.hasInputTarget && this.currentVideoUrlValue) {
      this.inputTarget.value = this.currentVideoUrlValue
    }

    // クリック外で結果を閉じる
    this.handleClickOutside = this.handleClickOutside.bind(this)
    document.addEventListener("click", this.handleClickOutside)
  }

  disconnect() {
    document.removeEventListener("click", this.handleClickOutside)
  }

  // 統合入力ハンドラー（検索またはURL）
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
      // URL入力の場合 → プレビュー表示
      this.showUrlDetected(value, videoId)
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
        item.style.background = "#f3f4f6"
      } else {
        item.style.background = "white"
      }
    })
  }

  // URL検出時の表示
  showUrlDetected(url, videoId) {
    const thumbnail = `https://img.youtube.com/vi/${videoId}/mqdefault.jpg`

    this.resultsTarget.innerHTML = `
      <button type="button"
              style="width: 100%; display: flex; align-items: center; gap: 12px; padding: 12px; background: white; border: none; text-align: left; cursor: pointer;"
              data-action="click->entry-edit#selectUrl"
              data-url="${this.escapeHtml(url)}"
              data-video-id="${videoId}"
              data-index="0"
              onmouseover="this.style.background='#f9f9f9'"
              onmouseout="this.style.background='white'">
        <img src="${thumbnail}" alt="" style="width: 80px; height: 45px; object-fit: cover; border-radius: 4px; flex-shrink: 0;">
        <div style="flex: 1;">
          <p style="font-size: 14px; font-weight: 500; color: #333; margin: 0;">この動画を選択</p>
          <p style="font-size: 12px; color: #888; margin: 0;">クリックで選択</p>
        </div>
        <svg style="width: 20px; height: 20px; color: #16a34a;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7"/>
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
        <div style="padding: 16px; text-align: center; color: #888; font-size: 14px;">
          <div style="display: inline-block; width: 16px; height: 16px; border: 2px solid #e0e0e0; border-top-color: #333; border-radius: 50%; animation: spin 1s linear infinite; margin-right: 8px;"></div>
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
      this.resultsTarget.innerHTML = '<p style="text-align: center; color: #888; padding: 16px; font-size: 14px;">検索に失敗しました</p>'
    }
  }

  // 検索結果を描画
  renderResults(videos) {
    if (videos.length === 0) {
      this.resultsTarget.innerHTML = '<p style="text-align: center; color: #888; padding: 16px; font-size: 14px;">動画が見つかりません</p>'
      return
    }

    const html = videos.map((video, index) => `
      <button type="button"
              style="width: 100%; display: flex; align-items: flex-start; gap: 12px; padding: 12px; background: white; border: none; border-bottom: 1px solid #f3f4f6; text-align: left; cursor: pointer;"
              data-action="click->entry-edit#selectVideo"
              data-url="${video.youtube_url}"
              data-video-id="${this.extractVideoId(video.youtube_url)}"
              data-title="${this.escapeHtml(video.title)}"
              data-channel="${this.escapeHtml(video.channel_name)}"
              data-thumbnail="${video.thumbnail_url}"
              data-index="${index}"
              onmouseover="this.style.background='#f9f9f9'"
              onmouseout="this.style.background='white'">
        <img src="${video.thumbnail_url}" alt="" style="width: 80px; height: 45px; object-fit: cover; border-radius: 4px; flex-shrink: 0;">
        <div style="flex: 1; min-width: 0;">
          <p style="font-size: 14px; font-weight: 500; color: #333; margin: 0; line-height: 1.4; display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden;">${this.escapeHtml(video.title)}</p>
          <p style="font-size: 12px; color: #888; margin-top: 2px;">${this.escapeHtml(video.channel_name)}</p>
        </div>
      </button>
    `).join("")

    this.resultsTarget.innerHTML = html
    this.selectedIndex = -1
  }

  // URL選択時
  async selectUrl(event) {
    const url = event.currentTarget.dataset.url
    const videoId = event.currentTarget.dataset.videoId

    // ローディング表示
    this.hideResults()
    this.previewTitleTarget.textContent = "読み込み中..."
    this.previewChannelTarget.textContent = ""

    try {
      // 動画情報を取得するためにYouTube検索
      const response = await fetch(`${this.youtubeUrlValue}?q=${videoId}`, {
        headers: { "Accept": "application/json" }
      })

      if (response.ok) {
        const videos = await response.json()
        if (videos.length > 0) {
          this.setSelectedVideo({
            url: url,
            videoId: videoId,
            title: videos[0].title,
            channel: videos[0].channel_name,
            thumbnail: videos[0].thumbnail_url
          })
          return
        }
      }

      // フォールバック: 基本情報のみ
      this.setSelectedVideo({
        url: url,
        videoId: videoId,
        title: "動画",
        channel: "",
        thumbnail: `https://img.youtube.com/vi/${videoId}/mqdefault.jpg`
      })
    } catch (error) {
      // フォールバック
      this.setSelectedVideo({
        url: url,
        videoId: videoId,
        title: "動画",
        channel: "",
        thumbnail: `https://img.youtube.com/vi/${videoId}/mqdefault.jpg`
      })
    }
  }

  // 動画選択時
  selectVideo(event) {
    const data = event.currentTarget.dataset
    this.setSelectedVideo({
      url: data.url,
      videoId: data.videoId,
      title: data.title,
      channel: data.channel,
      thumbnail: data.thumbnail
    })
  }

  // 選択した動画を設定
  setSelectedVideo(video) {
    // 動画が変わったかチェック
    this.videoChanged = video.videoId !== this.currentVideoIdValue

    this.selectedVideo = {
      videoId: video.videoId,
      title: video.title,
      channel: video.channel,
      url: video.url,
      thumbnail: video.thumbnail
    }

    this.hideResults()
    this.inputTarget.value = video.url

    // プレビュー表示・更新
    this.previewTarget.style.display = "block"
    const hqThumbnail = video.thumbnail.replace('mqdefault', 'sddefault')
    this.previewThumbnailTarget.src = hqThumbnail
    this.previewTitleTarget.textContent = video.title
    this.previewChannelTarget.textContent = video.channel

    // アクションプラン入力にフォーカス
    setTimeout(() => {
      this.actionPlanInputTarget.focus()
    }, 100)
  }

  // 動画選択をクリア（新規投稿と同じ動作）
  clearSelection(event) {
    console.log("clearSelection called")

    if (event) {
      event.preventDefault()
      event.stopPropagation()
    }

    this.selectedVideo = null
    this.videoChanged = true
    this.inputTarget.value = ""
    this.previewTarget.style.display = "none"
    this.inputTarget.focus()

    console.log("clearSelection completed")
  }

  // テキスト入力時
  handleActionPlanInput() {
    const text = this.actionPlanInputTarget.value.trim()
    // プレビューテキストを更新
    if (this.hasPreviewTextTarget) {
      this.previewTextTarget.textContent = text || 'アクションプランがここに表示されます'
    }
  }

  // フォーカス時
  focusInput() {
    if (this.hasInputWrapperTarget) {
      this.inputWrapperTarget.style.borderColor = "#333"
    }
  }

  // ブラー時
  blurInput() {
    if (this.hasInputWrapperTarget) {
      this.inputWrapperTarget.style.borderColor = "#e0e0e0"
    }
  }

  // 画像選択
  handleFileSelect(event) {
    console.log("[entry-edit] handleFileSelect called")
    const file = event.target.files[0]
    if (!file) {
      console.log("[entry-edit] No file selected")
      return
    }

    console.log("[entry-edit] File selected:", file.name, file.size, "bytes")

    // ファイルサイズチェック（5MB）
    if (file.size > 5 * 1024 * 1024) {
      alert('ファイルサイズは5MB以下にしてください')
      return
    }

    // 画像をBase64に変換
    const reader = new FileReader()
    reader.onload = (e) => {
      this.thumbnailData = e.target.result
      this.thumbnailCleared = false
      console.log("[entry-edit] thumbnailData set, length:", this.thumbnailData.length)

      // プレースホルダーを非表示、画像を表示
      if (this.hasUploadPlaceholderTarget) {
        this.uploadPlaceholderTarget.style.display = 'none'
      }
      if (this.hasPreviewImageTarget) {
        this.previewImageTarget.style.display = 'block'
        this.previewImageTarget.src = e.target.result
      }
      // ×ボタンを表示
      if (this.hasClearImageButtonTarget) {
        this.clearImageButtonTarget.style.display = 'flex'
      }
    }
    reader.readAsDataURL(file)
  }

  // 画像をクリア
  clearImage(event) {
    event.preventDefault()
    event.stopPropagation()

    this.thumbnailData = null
    this.thumbnailCleared = true

    // 画像を非表示、プレースホルダーを表示
    if (this.hasPreviewImageTarget) {
      this.previewImageTarget.style.display = 'none'
      this.previewImageTarget.src = ''
    }
    if (this.hasUploadPlaceholderTarget) {
      this.uploadPlaceholderTarget.style.display = 'flex'
    }
    // ×ボタンを非表示
    if (this.hasClearImageButtonTarget) {
      this.clearImageButtonTarget.style.display = 'none'
    }
    // ファイル入力をリセット
    if (this.hasFileInputTarget) {
      this.fileInputTarget.value = ''
    }
  }

  // フォーム送信
  async submitForm() {
    const content = this.actionPlanInputTarget.value.trim()

    console.log("[entry-edit] submitForm called")
    console.log("[entry-edit] thumbnailData:", this.thumbnailData ? `set (${this.thumbnailData.length} chars)` : "null")
    console.log("[entry-edit] thumbnailCleared:", this.thumbnailCleared)

    if (!this.selectedVideo) {
      alert('動画を選択してください')
      return
    }

    if (!content) {
      alert('アクションプランを入力してください')
      return
    }

    // ボタンをローディング状態に
    this.submitButtonTarget.disabled = true
    this.submitButtonTarget.textContent = '保存中...'

    const thumbnailToSend = this.thumbnailCleared ? "CLEAR" : this.thumbnailData
    console.log("[entry-edit] Sending thumbnail_data:", thumbnailToSend ? `${thumbnailToSend.substring(0, 50)}...` : "null")

    try {
      // JSONでPATCHリクエスト
      const response = await fetch(this.updateUrlValue, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content
        },
        body: JSON.stringify({
          post_entry: {
            content: content,
            thumbnail_data: thumbnailToSend,
            new_video_url: this.videoChanged ? this.selectedVideo.url : null
          }
        })
      })

      const data = await response.json()

      if (data.success) {
        // 成功 → リダイレクト（動画変更時は新しいURLを使用）
        const redirectUrl = data.redirect_url || this.redirectUrlValue
        if (window.Turbo) {
          window.Turbo.visit(redirectUrl)
        } else {
          window.location.href = redirectUrl
        }
      } else {
        alert(data.error || "更新に失敗しました")
        this.submitButtonTarget.disabled = false
        this.submitButtonTarget.textContent = '保存'
      }
    } catch (error) {
      console.error("Update error:", error)
      alert("更新に失敗しました")
      this.submitButtonTarget.disabled = false
      this.submitButtonTarget.textContent = '保存'
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
    this.resultsTarget.style.display = "block"
  }

  // 結果を非表示
  hideResults() {
    this.resultsTarget.style.display = "none"
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
