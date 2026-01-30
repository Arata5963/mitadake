// 投稿編集コントローラー
// 動画選択 + アクションプラン入力 + サムネイル画像の編集を処理

import { Controller } from "@hotwired/stimulus"                // Stimulusコントローラー基底クラス
import { extractVideoId, getThumbnailUrl } from "utils/youtube_helpers"
import { escapeHtml, fetchJson } from "utils/html_helpers"
import { uploadToS3, isValidFileSize } from "utils/s3_uploader"

export default class extends Controller {
  static targets = [
    "input", "results", "inputWrapper",
    "preview", "previewThumbnail", "previewTitle", "previewChannel",
    "actionPlanInput", "submitButton",
    "collectionPreview", "previewCard", "previewImage", "previewActionPlan",
    "uploadPlaceholder", "fileInput", "clearImageButton"
  ]

  static values = {
    youtubeUrl: String,                                        // YouTube検索APIのURL
    updateUrl: String,                                         // 投稿更新APIのURL
    minLength: { type: Number, default: 2 },                   // 検索開始の最小文字数
    initialVideoId: String,                                    // 初期動画ID
    initialTitle: String,                                      // 初期タイトル
    initialChannel: String,                                    // 初期チャンネル名
    initialThumbnail: String,                                  // 初期サムネイル
    initialActionPlan: String                                  // 初期アクションプラン
  }

  // 初期化（初期値から選択済み動画を設定）
  connect() {
    this.timeout = null
    this.selectedIndex = -1
    this.selectedFile = null
    this.uploadedS3Key = null
    this.selectedVideo = {
      videoId: this.initialVideoIdValue,
      title: this.initialTitleValue,
      channel: this.initialChannelValue,
      thumbnail: this.initialThumbnailValue,
      url: `https://www.youtube.com/watch?v=${this.initialVideoIdValue}`
    }
    this.handleClickOutside = this.handleClickOutside.bind(this)
    document.addEventListener("click", this.handleClickOutside)
  }

  disconnect() { document.removeEventListener("click", this.handleClickOutside) }

  // 入力時のハンドラー
  handleInput() {
    clearTimeout(this.timeout)
    const value = this.inputTarget.value.trim()
    if (!value) { this.hideResults(); return }
    const videoId = extractVideoId(value)
    if (videoId) { this.showUrlDetected(value, videoId) }
    else if (value.length >= this.minLengthValue) { this.timeout = setTimeout(() => this.fetchResults(value), 300) }
    else { this.hideResults() }
  }

  handleKeydown(event) {
    const items = this.resultsTarget.querySelectorAll("[data-index]")
    switch (event.key) {
      case "ArrowDown": event.preventDefault(); this.selectedIndex = Math.min(this.selectedIndex + 1, items.length - 1); this.updateSelection(items); break
      case "ArrowUp": event.preventDefault(); this.selectedIndex = Math.max(this.selectedIndex - 1, -1); this.updateSelection(items); break
      case "Enter": event.preventDefault(); if (this.selectedIndex >= 0 && items[this.selectedIndex]) items[this.selectedIndex].click(); break
      case "Escape": this.hideResults(); this.inputTarget.blur(); break
    }
  }

  updateSelection(items) { items.forEach((item, i) => item.classList.toggle("bg-gray-100", i === this.selectedIndex)) }

  showUrlDetected(url, videoId) {
    const thumbnail = getThumbnailUrl(videoId)
    this.resultsTarget.innerHTML = `
      <button type="button" class="w-full flex items-center gap-3 p-3 hover:bg-gray-50 transition-colors text-left"
              data-action="click->post-edit#selectUrl" data-url="${escapeHtml(url)}" data-video-id="${videoId}" data-index="0">
        <img src="${thumbnail}" alt="" class="w-20 h-12 object-cover rounded flex-shrink-0">
        <div class="flex-1"><p class="text-sm font-medium text-gray-900">この動画を選択</p><p class="text-xs text-gray-500">クリックで選択</p></div>
        <svg class="w-5 h-5 text-green-500" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7"/></svg>
      </button>`
    this.selectedIndex = 0
    this.showResults()
  }

  async fetchResults(query) {
    try {
      this.resultsTarget.innerHTML = `<div class="p-4 text-center text-gray-500 text-sm"><div class="inline-block w-4 h-4 border-2 border-gray-300 border-t-gray-600 rounded-full animate-spin mr-2"></div>検索中...</div>`
      this.showResults()
      const response = await fetch(`${this.youtubeUrlValue}?q=${encodeURIComponent(query)}`, { headers: { "Accept": "application/json" } })
      if (!response.ok) throw new Error("Search failed")
      this.renderResults(await response.json())
    } catch (error) { console.error("YouTube search error:", error); this.resultsTarget.innerHTML = '<p class="text-center text-gray-500 p-4 text-sm">検索に失敗しました</p>' }
  }

  renderResults(videos) {
    if (videos.length === 0) { this.resultsTarget.innerHTML = '<p class="text-center text-gray-500 p-4 text-sm">動画が見つかりません</p>'; return }
    this.resultsTarget.innerHTML = videos.map((video, index) => `
      <button type="button" class="w-full flex items-start gap-3 p-3 hover:bg-gray-50 transition-colors text-left border-b border-gray-100 last:border-b-0"
              data-action="click->post-edit#selectVideo" data-url="${video.youtube_url}" data-video-id="${extractVideoId(video.youtube_url)}"
              data-title="${escapeHtml(video.title)}" data-channel="${escapeHtml(video.channel_name)}" data-thumbnail="${video.thumbnail_url}" data-index="${index}">
        <img src="${video.thumbnail_url}" alt="" class="w-20 h-12 object-cover rounded flex-shrink-0">
        <div class="flex-1 min-w-0"><p class="text-sm font-medium text-gray-900 line-clamp-2">${escapeHtml(video.title)}</p><p class="text-xs text-gray-500 mt-0.5">${escapeHtml(video.channel_name)}</p></div>
      </button>`).join("")
    this.selectedIndex = -1
  }

  showResults() { this.resultsTarget.style.display = "block" }
  hideResults() { this.resultsTarget.style.display = "none"; this.resultsTarget.innerHTML = ""; this.selectedIndex = -1 }
  handleClickOutside(event) { if (!this.element.contains(event.target)) this.hideResults() }

  async selectUrl(event) {
    const url = event.currentTarget.dataset.url
    const videoId = event.currentTarget.dataset.videoId
    this.showLoadingPreview()
    try {
      const response = await fetch(`${this.youtubeUrlValue}?q=${videoId}`, { headers: { "Accept": "application/json" } })
      if (response.ok) {
        const videos = await response.json()
        if (videos.length > 0) { this.setSelectedVideo({ url, videoId, title: videos[0].title, channel: videos[0].channel_name, thumbnail: videos[0].thumbnail_url }); return }
      }
      this.setSelectedVideoFallback(url, videoId)
    } catch (error) { this.setSelectedVideoFallback(url, videoId) }
  }

  selectVideo(event) {
    const { url, videoId, title, channel, thumbnail } = event.currentTarget.dataset
    this.setSelectedVideo({ url, videoId, title, channel, thumbnail })
  }

  setSelectedVideoFallback(url, videoId) { this.setSelectedVideo({ url, videoId, title: "動画", channel: "", thumbnail: getThumbnailUrl(videoId) }) }

  showLoadingPreview() {
    this.hideResults()
    this.previewTarget.style.display = "block"
    this.previewThumbnailTarget.src = ""
    this.previewTitleTarget.textContent = "読み込み中..."
    this.previewChannelTarget.textContent = ""
  }

  setSelectedVideo(video) {
    this.selectedVideo = video
    this.hideResults()
    this.inputTarget.value = ""
    this.previewTarget.style.display = "block"
    this.previewThumbnailTarget.src = video.thumbnail.replace('mqdefault', 'sddefault')
    this.previewTitleTarget.textContent = video.title
    this.previewChannelTarget.textContent = video.channel
  }

  clearSelection() {
    this.selectedVideo = { videoId: this.initialVideoIdValue, title: this.initialTitleValue, channel: this.initialChannelValue, thumbnail: this.initialThumbnailValue, url: `https://www.youtube.com/watch?v=${this.initialVideoIdValue}` }
    this.inputTarget.value = ""
    this.previewThumbnailTarget.src = this.initialThumbnailValue
    this.previewTitleTarget.textContent = this.initialTitleValue
    this.previewChannelTarget.textContent = this.initialChannelValue
    this.previewTarget.style.display = "block"
  }

  handleActionPlanInput() { this.autoResizeTextarea(); this.updateCollectionPreview() }
  autoResizeTextarea() { const textarea = this.actionPlanInputTarget; textarea.style.height = "auto"; textarea.style.height = textarea.scrollHeight + "px" }
  focusInput() { if (this.hasInputWrapperTarget) this.inputWrapperTarget.style.borderColor = "#333" }
  blurInput() { if (this.hasInputWrapperTarget) this.inputWrapperTarget.style.borderColor = "#e0e0e0" }

  handleFileSelect(event) {
    const file = event.target.files[0]
    if (!file) return
    if (!isValidFileSize(file, 10)) { alert('ファイルサイズは10MB以下にしてください'); return }
    this.selectedFile = file
    this.uploadedS3Key = null
    const previewUrl = URL.createObjectURL(file)
    if (this.hasUploadPlaceholderTarget) this.uploadPlaceholderTarget.style.display = 'none'
    if (this.hasPreviewImageTarget) { this.previewImageTarget.style.display = 'block'; this.previewImageTarget.src = previewUrl }
    if (this.hasClearImageButtonTarget) this.clearImageButtonTarget.style.display = 'flex'
  }

  clearImage(event) {
    event.preventDefault()
    event.stopPropagation()
    this.selectedFile = null
    this.uploadedS3Key = null
    if (this.hasPreviewImageTarget) { this.previewImageTarget.style.display = 'none'; this.previewImageTarget.src = '' }
    if (this.hasUploadPlaceholderTarget) this.uploadPlaceholderTarget.style.display = 'flex'
    if (this.hasClearImageButtonTarget) this.clearImageButtonTarget.style.display = 'none'
    if (this.hasFileInputTarget) this.fileInputTarget.value = ''
  }

  updateCollectionPreview() {
    if (!this.hasPreviewActionPlanTarget) return
    this.previewActionPlanTarget.textContent = this.actionPlanInputTarget.value.trim() || 'アクションプランがここに表示されます'
  }

  async submitForm(event) {
    event.preventDefault()
    if (!this.selectedVideo || !this.actionPlanInputTarget.value.trim()) { alert("動画とアクションプランを入力してください"); return }
    const originalText = this.submitButtonTarget.innerHTML
    this.submitButtonTarget.disabled = true
    try {
      let s3Key = this.uploadedS3Key
      if (this.selectedFile && !s3Key) { this.submitButtonTarget.innerHTML = `<div class="inline-block w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin mr-2"></div>画像アップロード中...`; s3Key = await uploadToS3(this.selectedFile); this.uploadedS3Key = s3Key }
      this.submitButtonTarget.innerHTML = `<div class="inline-block w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin mr-2"></div>更新中...`
      const response = await fetchJson(this.updateUrlValue, { method: "PATCH", body: JSON.stringify({ youtube_url: this.selectedVideo.url, action_plan: this.actionPlanInputTarget.value.trim(), thumbnail_s3_key: s3Key }) })
      const data = await response.json()
      if (data.success && data.url) { if (window.Turbo) window.Turbo.visit(data.url); else window.location.href = data.url }
      else { alert(data.error || "更新に失敗しました"); this.submitButtonTarget.disabled = false; this.submitButtonTarget.innerHTML = originalText }
    } catch (error) { console.error("Submit error:", error); alert(error.message || "更新に失敗しました"); this.submitButtonTarget.disabled = false; this.submitButtonTarget.innerHTML = originalText }
  }
}
