// 新規投稿（アクションプラン作成）コントローラー
// 動画選択 + アクションプラン入力 + サムネイル画像を1つのフォームで処理

import { Controller } from "@hotwired/stimulus"                // Stimulusコントローラー基底クラス
import { extractVideoId, getThumbnailUrl } from "utils/youtube_helpers"
import { escapeHtml, fetchJson } from "utils/html_helpers"
import { uploadToS3, isValidFileSize } from "utils/s3_uploader"

export default class extends Controller {
  static targets = [
    "input", "results", "pasteButton", "inputWrapper", "searchArea",
    "preview", "previewThumbnail", "previewTitle", "previewChannel",
    "actionPlanInput", "submitButton", "form",
    "suggestions", "suggestionsContainer", "suggestButton", "convertButton",
    "collectionPreview", "previewCard", "previewImage", "previewActionPlan",
    "uploadPlaceholder", "fileInput", "clearImageButton"
  ]

  static values = {
    youtubeUrl: String,                                        // YouTube検索APIのURL
    createUrl: String,                                         // 投稿作成APIのURL
    suggestUrl: String,                                        // AI提案APIのURL
    convertUrl: String,                                        // タイトル変換APIのURL
    minLength: { type: Number, default: 2 }                    // 検索開始の最小文字数
  }

  // 初期化
  connect() {
    this.timeout = null                                        // デバウンス用タイマー
    this.selectedIndex = -1                                    // キーボード選択のインデックス
    this.selectedVideo = null                                  // 選択中の動画
    this.selectedFile = null                                   // 選択中のファイル
    this.uploadedS3Key = null                                  // アップロード済みS3キー
    this.handleClickOutside = this.handleClickOutside.bind(this)
    document.addEventListener("click", this.handleClickOutside)
  }

  // クリーンアップ
  disconnect() {
    document.removeEventListener("click", this.handleClickOutside)
  }

  // 入力時のハンドラー（URL検出またはキーワード検索）
  handleInput() {
    clearTimeout(this.timeout)
    const value = this.inputTarget.value.trim()
    if (!value) { this.hideResults(); return }

    const videoId = extractVideoId(value)
    if (videoId) {
      this.showUrlDetected(value, videoId)                     // URL検出
    } else if (value.length >= this.minLengthValue) {
      this.timeout = setTimeout(() => this.fetchResults(value), 300)  // キーワード検索
    } else {
      this.hideResults()
    }
  }

  // キーボードナビゲーション
  handleKeydown(event) {
    const items = this.resultsTarget.querySelectorAll("[data-index]")
    switch (event.key) {
      case "ArrowDown": event.preventDefault(); this.selectedIndex = Math.min(this.selectedIndex + 1, items.length - 1); this.updateSelection(items); break
      case "ArrowUp": event.preventDefault(); this.selectedIndex = Math.max(this.selectedIndex - 1, -1); this.updateSelection(items); break
      case "Enter": event.preventDefault(); if (this.selectedIndex >= 0 && items[this.selectedIndex]) items[this.selectedIndex].click(); break
      case "Escape": this.hideResults(); this.inputTarget.blur(); break
    }
  }

  // 選択状態のハイライト更新
  updateSelection(items) {
    items.forEach((item, i) => item.classList.toggle("bg-gray-100", i === this.selectedIndex))
  }

  // クリップボードから貼り付け
  async pasteFromClipboard() {
    try {
      const text = await navigator.clipboard.readText()
      if (text) { this.inputTarget.value = text.trim(); this.inputTarget.focus(); this.handleInput() }
    } catch (error) { console.log("Clipboard read failed:", error.message); this.inputTarget.focus() }
  }

  // URL検出時のUI表示
  showUrlDetected(url, videoId) {
    const thumbnail = getThumbnailUrl(videoId)
    this.resultsTarget.innerHTML = `
      <button type="button" class="w-full flex items-center gap-3 p-3 hover:bg-gray-50 transition-colors text-left"
              data-action="click->post-create#selectUrl" data-url="${escapeHtml(url)}" data-video-id="${videoId}" data-index="0">
        <img src="${thumbnail}" alt="" class="w-20 h-12 object-cover rounded flex-shrink-0">
        <div class="flex-1"><p class="text-sm font-medium text-gray-900">この動画を選択</p><p class="text-xs text-gray-500">クリックで選択</p></div>
        <svg class="w-5 h-5 text-green-500" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7"/></svg>
      </button>`
    this.selectedIndex = 0
    this.showResults()
  }

  // キーワード検索実行
  async fetchResults(query) {
    try {
      this.resultsTarget.innerHTML = `<div class="p-4 text-center text-gray-500 text-sm"><div class="inline-block w-4 h-4 border-2 border-gray-300 border-t-gray-600 rounded-full animate-spin mr-2"></div>検索中...</div>`
      this.showResults()
      const response = await fetch(`${this.youtubeUrlValue}?q=${encodeURIComponent(query)}`, { headers: { "Accept": "application/json" } })
      if (!response.ok) throw new Error("Search failed")
      const videos = await response.json()
      this.renderResults(videos)
    } catch (error) { console.error("YouTube search error:", error); this.resultsTarget.innerHTML = '<p class="text-center text-gray-500 p-4 text-sm">検索に失敗しました</p>' }
  }

  // 検索結果を描画
  renderResults(videos) {
    if (videos.length === 0) { this.resultsTarget.innerHTML = '<p class="text-center text-gray-500 p-4 text-sm">動画が見つかりません</p>'; return }
    this.resultsTarget.innerHTML = videos.map((video, index) => `
      <button type="button" class="w-full flex items-start gap-3 p-3 hover:bg-gray-50 transition-colors text-left border-b border-gray-100 last:border-b-0"
              data-action="click->post-create#selectVideo" data-url="${video.youtube_url}" data-video-id="${extractVideoId(video.youtube_url)}"
              data-title="${escapeHtml(video.title)}" data-channel="${escapeHtml(video.channel_name)}" data-thumbnail="${video.thumbnail_url}" data-index="${index}">
        <img src="${video.thumbnail_url}" alt="" class="w-20 h-12 object-cover rounded flex-shrink-0">
        <div class="flex-1 min-w-0"><p class="text-sm font-medium text-gray-900 line-clamp-2">${escapeHtml(video.title)}</p><p class="text-xs text-gray-500 mt-0.5">${escapeHtml(video.channel_name)}</p></div>
      </button>`).join("")
    this.selectedIndex = -1
  }

  showResults() { this.resultsTarget.style.display = "block" }
  hideResults() { this.resultsTarget.style.display = "none"; this.resultsTarget.innerHTML = ""; this.selectedIndex = -1 }
  handleClickOutside(event) { if (!this.element.contains(event.target)) this.hideResults() }

  // URL選択時に動画情報を取得
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

  // 検索結果から動画選択
  selectVideo(event) {
    const { url, videoId, title, channel, thumbnail } = event.currentTarget.dataset
    this.setSelectedVideo({ url, videoId, title, channel, thumbnail })
  }

  // フォールバック（タイトル取得失敗時）
  setSelectedVideoFallback(url, videoId) { this.setSelectedVideo({ url, videoId, title: "動画", channel: "", thumbnail: getThumbnailUrl(videoId) }) }

  // ローディングプレビュー表示
  showLoadingPreview() {
    this.hideResults()
    this.previewTarget.style.display = "block"
    this.previewThumbnailTarget.src = ""
    this.previewTitleTarget.textContent = "読み込み中..."
    this.previewChannelTarget.textContent = ""
  }

  // 動画選択を確定
  setSelectedVideo(video) {
    this.selectedVideo = video
    this.hideResults()
    if (this.hasSearchAreaTarget) this.searchAreaTarget.style.display = "none"
    this.previewTarget.style.display = "block"
    this.previewThumbnailTarget.src = video.thumbnail.replace('mqdefault', 'sddefault')
    this.previewTitleTarget.textContent = video.title
    this.previewChannelTarget.textContent = video.channel
    this.showSuggestButton()
    if (this.hasCollectionPreviewTarget) this.collectionPreviewTarget.style.display = "block"
    setTimeout(() => this.actionPlanInputTarget.focus(), 100)
    this.updateSubmitButton()
    this.updateConvertButton()
  }

  // 動画選択をクリア
  clearSelection() {
    this.selectedVideo = null
    this.inputTarget.value = ""
    this.previewTarget.style.display = "none"
    if (this.hasSearchAreaTarget) this.searchAreaTarget.style.display = "block"
    this.hideSuggestions()
    this.updateSubmitButton()
    this.inputTarget.focus()
  }

  // AI提案ボタンを表示
  showSuggestButton() {
    if (this.hasSuggestionsTarget) this.suggestionsTarget.style.display = "block"
    if (this.hasSuggestionsContainerTarget) this.suggestionsContainerTarget.innerHTML = ""
  }

  // AI提案を非表示
  hideSuggestions() {
    if (this.hasSuggestionsTarget) this.suggestionsTarget.style.display = "none"
    if (this.hasSuggestionsContainerTarget) this.suggestionsContainerTarget.innerHTML = ""
  }

  // AI提案を取得
  async fetchAiSuggestions() {
    if (!this.selectedVideo) return
    if (this.hasSuggestButtonTarget) { this.suggestButtonTarget.disabled = true; this.suggestButtonTarget.innerHTML = `<div style="width: 12px; height: 12px; border: 2px solid #d1d5db; border-top-color: #333; border-radius: 50%; animation: spin 1s linear infinite;"></div><span>取得中</span>` }
    try {
      const response = await fetchJson(this.suggestUrlValue, { method: "POST", body: JSON.stringify({ video_id: this.selectedVideo.videoId, title: this.selectedVideo.title }) })
      const data = await response.json()
      if (data.success && data.action_plans?.length > 0) { this.renderSuggestions(data.action_plans); if (this.hasSuggestButtonTarget) this.suggestButtonTarget.style.display = "none" }
      else { this.showSuggestError("提案を取得できませんでした") }
    } catch (error) { console.error("AI suggestion error:", error); this.showSuggestError("提案を取得できませんでした") }
  }

  // AI提案エラー表示
  showSuggestError(message) {
    if (this.hasSuggestButtonTarget) { this.suggestButtonTarget.disabled = false; this.suggestButtonTarget.innerHTML = `AI提案` }
    if (this.hasSuggestionsContainerTarget) this.suggestionsContainerTarget.innerHTML = `<p style="font-size: 12px; color: #888; margin: 0 0 8px 0;">${message}</p>`
  }

  // AI提案を描画
  renderSuggestions(plans) {
    if (!this.hasSuggestionsContainerTarget) return
    this.suggestionsContainerTarget.innerHTML = plans.map(plan => `
      <button type="button" data-action="click->post-create#selectSuggestion" data-plan="${escapeHtml(plan)}" class="suggestion-item"
              style="display: flex; align-items: center; width: 100%; text-align: left; padding: 12px 14px; background: #fff; border: 1px solid #e0e0e0; border-radius: 8px; margin-bottom: 8px; font-size: 14px; color: #333; cursor: pointer; transition: all 0.15s;"
              onmouseover="this.style.background='#f5f5f5'; this.style.borderColor='#333';" onmouseout="this.style.background='#fff'; this.style.borderColor='#e0e0e0';">
        <span style="flex: 1;">${escapeHtml(plan)}</span><span style="flex-shrink: 0; color: #888; font-size: 12px;">選択 →</span>
      </button>`).join("")
  }

  // AI提案を選択
  selectSuggestion(event) {
    const plan = event.currentTarget.dataset.plan
    this.actionPlanInputTarget.value = plan
    this.updateSubmitButton()
    this.updateConvertButton()
    this.updateCollectionPreview()
    this.actionPlanInputTarget.focus()
  }

  // タイトル変換ボタンの表示制御
  updateConvertButton() {
    if (!this.hasConvertButtonTarget) return
    const hasText = this.actionPlanInputTarget.value.trim().length > 0
    this.convertButtonTarget.style.display = hasText && this.selectedVideo ? "inline-flex" : "none"
  }

  // タイトルをYouTube風に変換
  async convertToYouTubeTitle() {
    if (!this.hasConvertButtonTarget) return
    const actionPlan = this.actionPlanInputTarget.value.trim()
    if (!actionPlan) return
    const originalHtml = this.convertButtonTarget.innerHTML
    this.convertButtonTarget.disabled = true
    this.convertButtonTarget.innerHTML = `<div style="width: 12px; height: 12px; border: 2px solid #d1d5db; border-top-color: #333; border-radius: 50%; animation: spin 1s linear infinite;"></div><span>変換中...</span>`
    try {
      const response = await fetchJson(this.convertUrlValue, { method: "POST", body: JSON.stringify({ action_plan: actionPlan }) })
      const data = await response.json()
      if (data.success && data.title) { this.actionPlanInputTarget.value = data.title; this.updateSubmitButton(); this.autoResizeTextarea(); this.convertButtonTarget.innerHTML = originalHtml; this.convertButtonTarget.disabled = false; this.convertButtonTarget.style.display = "none" }
      else { alert(data.error || "変換に失敗しました"); this.convertButtonTarget.innerHTML = originalHtml; this.convertButtonTarget.disabled = false }
    } catch (error) { console.error("Convert error:", error); alert("変換に失敗しました"); this.convertButtonTarget.innerHTML = originalHtml; this.convertButtonTarget.disabled = false }
  }

  // アクションプラン入力時の処理
  handleActionPlanInput() { this.updateSubmitButton(); this.autoResizeTextarea(); this.updateConvertButton(); this.updateCollectionPreview() }
  autoResizeTextarea() { const textarea = this.actionPlanInputTarget; textarea.style.height = "auto"; textarea.style.height = textarea.scrollHeight + "px" }
  focusInput() { if (this.hasInputWrapperTarget) this.inputWrapperTarget.style.borderColor = "#333" }
  blurInput() { if (this.hasInputWrapperTarget) this.inputWrapperTarget.style.borderColor = "#e0e0e0" }

  // 画像選択時の処理
  handleFileSelect(event) {
    const file = event.target.files[0]
    if (!file) return
    if (!isValidFileSize(file, 5)) { alert('ファイルサイズは5MB以下にしてください'); return }
    this.selectedFile = file
    this.uploadedS3Key = null
    const previewUrl = URL.createObjectURL(file)
    if (this.hasUploadPlaceholderTarget) this.uploadPlaceholderTarget.style.display = 'none'
    if (this.hasPreviewImageTarget) { this.previewImageTarget.style.display = 'block'; this.previewImageTarget.src = previewUrl }
    if (this.hasClearImageButtonTarget) this.clearImageButtonTarget.style.display = 'flex'
    this.updateSubmitButton()
  }

  // 画像をクリア
  clearImage(event) {
    event.preventDefault()
    event.stopPropagation()
    this.selectedFile = null
    this.uploadedS3Key = null
    if (this.hasPreviewImageTarget) { this.previewImageTarget.style.display = 'none'; this.previewImageTarget.src = '' }
    if (this.hasUploadPlaceholderTarget) this.uploadPlaceholderTarget.style.display = 'flex'
    if (this.hasClearImageButtonTarget) this.clearImageButtonTarget.style.display = 'none'
    if (this.hasFileInputTarget) this.fileInputTarget.value = ''
    this.updateSubmitButton()
  }

  // コレクションプレビューを更新
  updateCollectionPreview() {
    if (!this.hasPreviewActionPlanTarget) return
    const text = this.actionPlanInputTarget.value.trim() || 'アクションプランがここに表示されます'
    this.previewActionPlanTarget.textContent = text
  }

  // 送信ボタンの有効/無効を制御
  updateSubmitButton() {
    const hasVideo = !!this.selectedVideo
    const hasActionPlan = this.actionPlanInputTarget.value.trim().length > 0
    const hasImage = !!this.selectedFile || !!this.uploadedS3Key
    const canSubmit = hasVideo && hasActionPlan && hasImage
    this.submitButtonTarget.disabled = !canSubmit
    if (canSubmit) { this.submitButtonTarget.classList.remove("bg-gray-300", "cursor-not-allowed"); this.submitButtonTarget.classList.add("bg-gray-900", "hover:bg-gray-800", "cursor-pointer") }
    else { this.submitButtonTarget.classList.remove("bg-gray-900", "hover:bg-gray-800", "cursor-pointer"); this.submitButtonTarget.classList.add("bg-gray-300", "cursor-not-allowed") }
  }

  // フォーム送信
  async submitForm(event) {
    event.preventDefault()
    if (!this.selectedVideo || !this.actionPlanInputTarget.value.trim()) return
    const originalText = this.submitButtonTarget.innerHTML
    this.submitButtonTarget.disabled = true
    this.submitButtonTarget.innerHTML = `<div class="inline-block w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin mr-2"></div>画像アップロード中...`
    try {
      let s3Key = this.uploadedS3Key
      if (this.selectedFile && !s3Key) { s3Key = await uploadToS3(this.selectedFile); this.uploadedS3Key = s3Key }
      this.submitButtonTarget.innerHTML = `<div class="inline-block w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin mr-2"></div>投稿中...`
      const response = await fetchJson(this.createUrlValue, { method: "POST", body: JSON.stringify({ youtube_url: this.selectedVideo.url, action_plan: this.actionPlanInputTarget.value.trim(), thumbnail_s3_key: s3Key }) })
      const data = await response.json()
      if (data.success && data.url) {
        sessionStorage.setItem('pendingFlash', JSON.stringify({ type: 'notice', message: '投稿しました！' }))
        if (window.Turbo) window.Turbo.visit(data.url); else window.location.href = data.url
      } else { alert(data.error || "投稿に失敗しました"); this.submitButtonTarget.disabled = false; this.submitButtonTarget.innerHTML = originalText }
    } catch (error) { console.error("Submit error:", error); alert(error.message || "投稿に失敗しました"); this.submitButtonTarget.disabled = false; this.submitButtonTarget.innerHTML = originalText }
  }
}
