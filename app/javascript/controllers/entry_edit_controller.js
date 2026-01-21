// app/javascript/controllers/entry_edit_controller.js
// ==========================================
// アクションプラン編集コントローラー
// ==========================================
//
// 【このコントローラーの役割】
// 既存のアクションプランを編集する画面を制御。
// 動画変更、アクションプラン内容変更、サムネイル変更が可能。
//
// 【post_create_controller との違い】
// - post_create: 新規作成（動画+アクションプランを同時作成）
// - entry_edit: 既存のエントリーを編集（動画変更も可能）
//
// 【処理フロー】
//
//   1. 既存の動画・アクションプランを表示
//      ↓
//   2. ユーザーが編集
//      - 別の動画に変更可能
//      - アクションプラン内容を変更
//      - サムネイル画像を変更/削除
//      ↓
//   3. 送信 → PostEntry を更新
//
// 【機能一覧】
// - 既存動画の表示
// - 動画変更（YouTube検索）
// - アクションプラン編集
// - サムネイル変更/削除（S3署名付きURL）
// - フォーム送信
//
// 【Stimulusの概念】
// - values に現在の動画情報を渡す（編集開始時の初期値）
// - videoChanged フラグで動画が変更されたかを追跡
// - thumbnailCleared フラグでサムネイル削除を追跡
//

import { Controller } from "@hotwired/stimulus"
import { extractVideoId, getThumbnailUrl } from "utils/youtube_helpers"
import { escapeHtml, fetchJson } from "utils/html_helpers"
import { uploadToS3, isValidFileSize } from "utils/s3_uploader"

export default class extends Controller {
  static targets = [
    // 検索・入力
    "input", "results", "inputWrapper",
    // 動画プレビュー
    "preview", "previewThumbnail", "previewTitle", "previewChannel",
    // アクションプラン
    "actionPlanInput", "submitButton",
    // 画像アップロード
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

  // ===== ライフサイクル =====

  connect() {
    this.timeout = null
    this.selectedIndex = -1
    this.selectedFile = null
    this.uploadedS3Key = null
    this.thumbnailCleared = false
    this.videoChanged = false

    // 初期値として現在の動画情報をセット
    this.selectedVideo = {
      postId: this.currentPostIdValue,
      videoId: this.currentVideoIdValue,
      title: this.currentVideoTitleValue,
      channel: this.currentVideoChannelValue,
      url: this.currentVideoUrlValue,
      thumbnail: this.currentThumbnailValue
    }

    if (this.hasInputTarget && this.currentVideoUrlValue) {
      this.inputTarget.value = this.currentVideoUrlValue
    }

    this.handleClickOutside = this.handleClickOutside.bind(this)
    document.addEventListener("click", this.handleClickOutside)
  }

  disconnect() {
    document.removeEventListener("click", this.handleClickOutside)
  }

  // ===== 入力・検索 =====

  handleInput() {
    clearTimeout(this.timeout)
    const value = this.inputTarget.value.trim()

    if (!value) {
      this.hideResults()
      return
    }

    const videoId = extractVideoId(value)

    if (videoId) {
      this.showUrlDetected(value, videoId)
    } else if (value.length >= this.minLengthValue) {
      this.timeout = setTimeout(() => this.fetchResults(value), 300)
    } else {
      this.hideResults()
    }
  }

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
      item.style.background = i === this.selectedIndex ? "#f3f4f6" : "white"
    })
  }

  focusInput() {
    if (this.hasInputWrapperTarget) {
      this.inputWrapperTarget.style.borderColor = "#333"
    }
  }

  blurInput() {
    if (this.hasInputWrapperTarget) {
      this.inputWrapperTarget.style.borderColor = "#e0e0e0"
    }
  }

  // ===== 検索結果 =====

  showUrlDetected(url, videoId) {
    const thumbnail = getThumbnailUrl(videoId)

    this.resultsTarget.innerHTML = `
      <button type="button"
              style="width: 100%; display: flex; align-items: center; gap: 12px; padding: 12px; background: white; border: none; text-align: left; cursor: pointer;"
              data-action="click->entry-edit#selectUrl"
              data-url="${escapeHtml(url)}"
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

  async fetchResults(query) {
    try {
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

  renderResults(videos) {
    if (videos.length === 0) {
      this.resultsTarget.innerHTML = '<p style="text-align: center; color: #888; padding: 16px; font-size: 14px;">動画が見つかりません</p>'
      return
    }

    this.resultsTarget.innerHTML = videos.map((video, index) => `
      <button type="button"
              style="width: 100%; display: flex; align-items: flex-start; gap: 12px; padding: 12px; background: white; border: none; border-bottom: 1px solid #f3f4f6; text-align: left; cursor: pointer;"
              data-action="click->entry-edit#selectVideo"
              data-url="${video.youtube_url}"
              data-video-id="${extractVideoId(video.youtube_url)}"
              data-title="${escapeHtml(video.title)}"
              data-channel="${escapeHtml(video.channel_name)}"
              data-thumbnail="${video.thumbnail_url}"
              data-index="${index}"
              onmouseover="this.style.background='#f9f9f9'"
              onmouseout="this.style.background='white'">
        <img src="${video.thumbnail_url}" alt="" style="width: 80px; height: 45px; object-fit: cover; border-radius: 4px; flex-shrink: 0;">
        <div style="flex: 1; min-width: 0;">
          <p style="font-size: 14px; font-weight: 500; color: #333; margin: 0; line-height: 1.4; display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden;">${escapeHtml(video.title)}</p>
          <p style="font-size: 12px; color: #888; margin-top: 2px;">${escapeHtml(video.channel_name)}</p>
        </div>
      </button>
    `).join("")

    this.selectedIndex = -1
  }

  showResults() {
    this.resultsTarget.style.display = "block"
  }

  hideResults() {
    this.resultsTarget.style.display = "none"
    this.resultsTarget.innerHTML = ""
    this.selectedIndex = -1
  }

  handleClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.hideResults()
    }
  }

  // ===== 動画選択 =====

  async selectUrl(event) {
    const url = event.currentTarget.dataset.url
    const videoId = event.currentTarget.dataset.videoId

    this.hideResults()
    this.previewTitleTarget.textContent = "読み込み中..."
    this.previewChannelTarget.textContent = ""

    try {
      const response = await fetch(`${this.youtubeUrlValue}?q=${videoId}`, {
        headers: { "Accept": "application/json" }
      })

      if (response.ok) {
        const videos = await response.json()
        if (videos.length > 0) {
          this.setSelectedVideo({
            url, videoId,
            title: videos[0].title,
            channel: videos[0].channel_name,
            thumbnail: videos[0].thumbnail_url
          })
          return
        }
      }

      this.setSelectedVideoFallback(url, videoId)
    } catch (error) {
      this.setSelectedVideoFallback(url, videoId)
    }
  }

  selectVideo(event) {
    const { url, videoId, title, channel, thumbnail } = event.currentTarget.dataset
    this.setSelectedVideo({ url, videoId, title, channel, thumbnail })
  }

  setSelectedVideoFallback(url, videoId) {
    this.setSelectedVideo({
      url, videoId,
      title: "動画",
      channel: "",
      thumbnail: getThumbnailUrl(videoId)
    })
  }

  setSelectedVideo(video) {
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

    this.previewTarget.style.display = "block"
    this.previewThumbnailTarget.src = video.thumbnail.replace('mqdefault', 'sddefault')
    this.previewTitleTarget.textContent = video.title
    this.previewChannelTarget.textContent = video.channel

    setTimeout(() => this.actionPlanInputTarget.focus(), 100)
  }

  clearSelection(event) {
    if (event) {
      event.preventDefault()
      event.stopPropagation()
    }

    this.selectedVideo = null
    this.videoChanged = true
    this.inputTarget.value = ""
    this.previewTarget.style.display = "none"
    this.inputTarget.focus()
  }

  // ===== アクションプラン入力 =====

  handleActionPlanInput() {
    const text = this.actionPlanInputTarget.value.trim()
    if (this.hasPreviewTextTarget) {
      this.previewTextTarget.textContent = text || 'アクションプランがここに表示されます'
    }
  }

  // ===== 画像アップロード =====

  handleFileSelect(event) {
    const file = event.target.files[0]
    if (!file) return

    if (!isValidFileSize(file, 5)) {
      alert('ファイルサイズは5MB以下にしてください')
      return
    }

    this.selectedFile = file
    this.uploadedS3Key = null
    this.thumbnailCleared = false

    const previewUrl = URL.createObjectURL(file)

    if (this.hasUploadPlaceholderTarget) {
      this.uploadPlaceholderTarget.style.display = 'none'
    }
    if (this.hasPreviewImageTarget) {
      this.previewImageTarget.style.display = 'block'
      this.previewImageTarget.src = previewUrl
    }
    if (this.hasClearImageButtonTarget) {
      this.clearImageButtonTarget.style.display = 'flex'
    }
  }

  clearImage(event) {
    event.preventDefault()
    event.stopPropagation()

    this.selectedFile = null
    this.uploadedS3Key = null
    this.thumbnailCleared = true

    if (this.hasPreviewImageTarget) {
      this.previewImageTarget.style.display = 'none'
      this.previewImageTarget.src = ''
    }
    if (this.hasUploadPlaceholderTarget) {
      this.uploadPlaceholderTarget.style.display = 'flex'
    }
    if (this.hasClearImageButtonTarget) {
      this.clearImageButtonTarget.style.display = 'none'
    }
    if (this.hasFileInputTarget) {
      this.fileInputTarget.value = ''
    }
  }

  // ===== フォーム送信 =====

  async submitForm() {
    const content = this.actionPlanInputTarget.value.trim()

    if (!this.selectedVideo) {
      alert('動画を選択してください')
      return
    }

    if (!content) {
      alert('アクションプランを入力してください')
      return
    }

    this.submitButtonTarget.disabled = true
    this.submitButtonTarget.textContent = '保存中...'

    try {
      // 1. 画像がある場合はS3にアップロード
      let s3Key = null
      if (this.selectedFile) {
        this.submitButtonTarget.textContent = '画像アップロード中...'
        s3Key = await uploadToS3(this.selectedFile)
      }

      // 2. サーバーに更新リクエスト
      this.submitButtonTarget.textContent = '保存中...'

      const thumbnailValue = this.thumbnailCleared ? "CLEAR" : s3Key

      const response = await fetchJson(this.updateUrlValue, {
        method: "PATCH",
        body: JSON.stringify({
          post_entry: {
            content: content,
            thumbnail_s3_key: thumbnailValue,
            new_video_url: this.videoChanged ? this.selectedVideo.url : null
          }
        })
      })

      const data = await response.json()

      if (data.success) {
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
      alert(error.message || "更新に失敗しました")
      this.submitButtonTarget.disabled = false
      this.submitButtonTarget.textContent = '保存'
    }
  }
}
