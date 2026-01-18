// app/javascript/controllers/post_create_controller.js
import { Controller } from "@hotwired/stimulus"

// 新規投稿コントローラー
// 動画選択 + アクションプラン入力 → 同時作成
export default class extends Controller {
  static targets = [
    "input", "results", "pasteButton",
    "preview", "previewThumbnail", "previewTitle", "previewChannel",
    "actionPlanInput", "submitButton", "form",
    "step1", "step2",
    "suggestions", "suggestionsContainer", "suggestButton",
    "searchArea", "inputWrapper",
    "convertButton",
    // コレクションプレビュー（画像アップロード統合）
    "collectionPreview", "previewCard", "previewImage", "previewActionPlan",
    "uploadPlaceholder", "fileInput", "clearImageButton"
  ]
  static values = {
    youtubeUrl: String,
    createUrl: String,
    findOrCreateUrl: String,
    convertUrl: String,
    minLength: { type: Number, default: 2 }
  }

  connect() {
    this.timeout = null
    this.selectedIndex = -1
    this.selectedVideo = null
    this.postId = null
    // サムネイル（画像アップロード必須）
    this.selectedThumbnail = { key: 'custom', emoji: null, color: null, customImage: null }

    // クリック外で結果を閉じる
    this.handleClickOutside = this.handleClickOutside.bind(this)
    document.addEventListener("click", this.handleClickOutside)
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
      console.log("Clipboard read failed:", error.message)
      this.inputTarget.focus()
    }
  }

  // URL検出時の表示
  showUrlDetected(url, videoId) {
    const thumbnail = `https://img.youtube.com/vi/${videoId}/mqdefault.jpg`

    this.resultsTarget.innerHTML = `
      <button type="button"
              class="w-full flex items-center gap-3 p-3 hover:bg-gray-50 transition-colors text-left"
              data-action="click->post-create#selectUrl"
              data-url="${this.escapeHtml(url)}"
              data-video-id="${videoId}"
              data-index="0">
        <img src="${thumbnail}" alt="" class="w-20 h-12 object-cover rounded flex-shrink-0">
        <div class="flex-1">
          <p class="text-sm font-medium text-gray-900">この動画を選択</p>
          <p class="text-xs text-gray-500">クリックで選択</p>
        </div>
        <svg class="w-5 h-5 text-green-500" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
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
              data-action="click->post-create#selectVideo"
              data-url="${video.youtube_url}"
              data-video-id="${this.extractVideoId(video.youtube_url)}"
              data-title="${this.escapeHtml(video.title)}"
              data-channel="${this.escapeHtml(video.channel_name)}"
              data-thumbnail="${video.thumbnail_url}"
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
  async selectUrl(event) {
    const url = event.currentTarget.dataset.url
    const videoId = event.currentTarget.dataset.videoId

    // YouTube APIで動画情報を取得
    this.showLoadingPreview()

    try {
      // 動画情報を取得するためにfind_or_createを呼び出し（保存はしない）
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

  // ローディングプレビュー表示
  showLoadingPreview() {
    this.hideResults()
    this.previewTarget.style.display = "block"
    this.previewThumbnailTarget.src = ""
    this.previewTitleTarget.textContent = "読み込み中..."
    this.previewChannelTarget.textContent = ""
  }

  // 選択した動画を設定
  setSelectedVideo(video) {
    this.selectedVideo = video
    this.hideResults()

    // 検索エリアを非表示
    if (this.hasSearchAreaTarget) {
      this.searchAreaTarget.style.display = "none"
    }

    // プレビュー表示
    this.previewTarget.style.display = "block"
    // 高画質サムネイルを使用（sddefault or maxresdefault）
    const hqThumbnail = video.thumbnail.replace('mqdefault', 'sddefault')
    this.previewThumbnailTarget.src = hqThumbnail
    this.previewTitleTarget.textContent = video.title
    this.previewChannelTarget.textContent = video.channel

    // AI提案ボタンを表示
    this.showSuggestButton()

    // コレクションプレビューを表示（画像アップロード統合）
    if (this.hasCollectionPreviewTarget) {
      this.collectionPreviewTarget.style.display = "block"
    }

    // アクションプラン入力にフォーカス
    setTimeout(() => {
      this.actionPlanInputTarget.focus()
    }, 100)

    // 投稿ボタンの状態を更新
    this.updateSubmitButton()
    // 変換ボタンの状態を更新
    this.updateConvertButton()
  }

  // AI提案ボタンを表示
  showSuggestButton() {
    if (this.hasSuggestionsTarget) {
      this.suggestionsTarget.style.display = "block"
    }
    if (this.hasSuggestionsContainerTarget) {
      this.suggestionsContainerTarget.innerHTML = ""
    }
  }

  // AI提案を取得（ボタンクリック時）
  async fetchAiSuggestions() {
    if (!this.selectedVideo) return

    // ボタンをローディング状態に
    if (this.hasSuggestButtonTarget) {
      this.suggestButtonTarget.disabled = true
      this.suggestButtonTarget.innerHTML = `
        <div style="width: 12px; height: 12px; border: 2px solid #d1d5db; border-top-color: #333; border-radius: 50%; animation: spin 1s linear infinite;"></div>
        <span>取得中</span>
      `
    }

    try {
      // まず動画のPostを取得/作成
      const findResponse = await fetch(this.findOrCreateUrlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content
        },
        body: JSON.stringify({ youtube_url: this.selectedVideo.url })
      })

      const findData = await findResponse.json()
      if (!findData.success || !findData.post_id) {
        throw new Error("Failed to get post")
      }

      this.postId = findData.post_id

      // AI提案を取得
      const suggestResponse = await fetch(`/posts/${this.postId}/suggest_action_plans`, {
        method: "POST",
        headers: {
          "Accept": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content
        }
      })

      const suggestData = await suggestResponse.json()

      if (suggestData.success && suggestData.action_plans && suggestData.action_plans.length > 0) {
        this.renderSuggestions(suggestData.action_plans)
        // ボタンを非表示
        if (this.hasSuggestButtonTarget) {
          this.suggestButtonTarget.style.display = "none"
        }
      } else {
        this.showSuggestError("提案を取得できませんでした")
      }
    } catch (error) {
      console.error("AI suggestion error:", error)
      this.showSuggestError("提案を取得できませんでした")
    }
  }

  // AI提案エラー表示
  showSuggestError(message) {
    if (this.hasSuggestButtonTarget) {
      this.suggestButtonTarget.disabled = false
      this.suggestButtonTarget.innerHTML = `AI提案`
    }
    if (this.hasSuggestionsContainerTarget) {
      this.suggestionsContainerTarget.innerHTML = `
        <p style="font-size: 12px; color: #888; margin: 0 0 8px 0;">${message}</p>
      `
    }
  }

  // AI提案を描画
  renderSuggestions(plans) {
    if (!this.hasSuggestionsContainerTarget) return

    const items = plans.map(plan => `
      <button type="button"
              data-action="click->post-create#selectSuggestion"
              data-plan="${this.escapeHtml(plan)}"
              class="suggestion-item"
              style="display: flex; align-items: center; width: 100%; text-align: left; padding: 12px 14px; background: #fff; border: 1px solid #e0e0e0; border-radius: 8px; margin-bottom: 8px; font-size: 14px; color: #333; cursor: pointer; transition: all 0.15s;"
              onmouseover="this.style.background='#f5f5f5'; this.style.borderColor='#333';"
              onmouseout="this.style.background='#fff'; this.style.borderColor='#e0e0e0';">
        <span style="flex: 1;">${this.escapeHtml(plan)}</span>
        <span style="flex-shrink: 0; color: #888; font-size: 12px;">選択 →</span>
      </button>
    `).join("")

    this.suggestionsContainerTarget.innerHTML = items
  }

  // 提案を選択
  selectSuggestion(event) {
    const plan = event.currentTarget.dataset.plan
    this.actionPlanInputTarget.value = plan
    this.updateSubmitButton()
    this.updateConvertButton()
    this.actionPlanInputTarget.focus()
  }

  // AI提案エリアを非表示
  hideSuggestions() {
    if (this.hasSuggestionsTarget) {
      this.suggestionsTarget.style.display = "none"
    }
    if (this.hasSuggestionsContainerTarget) {
      this.suggestionsContainerTarget.innerHTML = ""
    }
  }

  // 動画選択をクリア
  clearSelection() {
    this.selectedVideo = null
    this.postId = null
    this.inputTarget.value = ""
    this.previewTarget.style.display = "none"

    // 検索エリアを再表示
    if (this.hasSearchAreaTarget) {
      this.searchAreaTarget.style.display = "block"
    }

    this.hideSuggestions()
    this.updateSubmitButton()
    this.inputTarget.focus()
  }

  // アクションプラン入力時
  handleActionPlanInput() {
    this.updateSubmitButton()
    // テキストエリアの高さを自動調整
    this.autoResizeTextarea()
    // 変換ボタンの表示/非表示
    this.updateConvertButton()
    // コレクションプレビュー更新
    this.updateCollectionPreview()
  }

  // 変換ボタンの表示/非表示
  updateConvertButton() {
    if (!this.hasConvertButtonTarget) return

    const text = this.actionPlanInputTarget.value.trim()
    if (text.length > 0 && this.selectedVideo) {
      this.convertButtonTarget.style.display = "inline-flex"
    } else {
      this.convertButtonTarget.style.display = "none"
    }
  }

  // アクションプランをYouTubeタイトル風に変換
  async convertToYouTubeTitle() {
    if (!this.hasConvertButtonTarget) return

    const actionPlan = this.actionPlanInputTarget.value.trim()
    if (!actionPlan) return

    // ボタンをローディング状態に
    const originalHtml = this.convertButtonTarget.innerHTML
    this.convertButtonTarget.disabled = true
    this.convertButtonTarget.innerHTML = `
      <div style="width: 12px; height: 12px; border: 2px solid #d1d5db; border-top-color: #333; border-radius: 50%; animation: spin 1s linear infinite;"></div>
      <span>変換中...</span>
    `

    try {
      const response = await fetch(this.convertUrlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content
        },
        body: JSON.stringify({ action_plan: actionPlan })
      })

      const data = await response.json()

      if (data.success && data.title) {
        // 変換後のタイトルを入力欄に設定
        this.actionPlanInputTarget.value = data.title
        this.updateSubmitButton()
        this.autoResizeTextarea()
        // ボタンを元の状態に戻してから非表示に
        this.convertButtonTarget.innerHTML = originalHtml
        this.convertButtonTarget.disabled = false
        this.convertButtonTarget.style.display = "none"
      } else {
        // エラー
        alert(data.error || "変換に失敗しました")
        this.convertButtonTarget.innerHTML = originalHtml
        this.convertButtonTarget.disabled = false
      }
    } catch (error) {
      console.error("Convert error:", error)
      alert("変換に失敗しました")
      this.convertButtonTarget.innerHTML = originalHtml
      this.convertButtonTarget.disabled = false
    }
  }

  // テキストエリアの高さを自動調整
  autoResizeTextarea() {
    const textarea = this.actionPlanInputTarget
    textarea.style.height = "auto"
    textarea.style.height = textarea.scrollHeight + "px"
  }

  // 入力フォーカス時
  focusInput() {
    if (this.hasInputWrapperTarget) {
      this.inputWrapperTarget.style.borderColor = "#333"
    }
  }

  // 入力ブラー時
  blurInput() {
    if (this.hasInputWrapperTarget) {
      this.inputWrapperTarget.style.borderColor = "#e0e0e0"
    }
  }

  // 投稿ボタンの状態を更新
  updateSubmitButton() {
    const hasVideo = !!this.selectedVideo
    const hasActionPlan = this.actionPlanInputTarget.value.trim().length > 0
    const hasImage = !!this.selectedThumbnail.customImage  // 画像必須
    const canSubmit = hasVideo && hasActionPlan && hasImage

    this.submitButtonTarget.disabled = !canSubmit

    if (canSubmit) {
      this.submitButtonTarget.style.background = "#333"
      this.submitButtonTarget.style.cursor = "pointer"
    } else {
      this.submitButtonTarget.style.background = "#c0c0c0"
      this.submitButtonTarget.style.cursor = "not-allowed"
    }
  }

  // フォーム送信
  async submitForm(event) {
    event.preventDefault()

    if (!this.selectedVideo || !this.actionPlanInputTarget.value.trim()) {
      return
    }

    // ボタンをローディング状態に
    const originalText = this.submitButtonTarget.innerHTML
    this.submitButtonTarget.disabled = true
    this.submitButtonTarget.innerHTML = `
      <div class="inline-block w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin mr-2"></div>
      投稿中...
    `

    try {
      const response = await fetch(this.createUrlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content
        },
        body: JSON.stringify({
          youtube_url: this.selectedVideo.url,
          action_plan: this.actionPlanInputTarget.value.trim(),
          thumbnail: this.selectedThumbnail
        })
      })

      const data = await response.json()

      if (data.success && data.url) {
        // 成功 → 詳細ページへ遷移
        if (window.Turbo) {
          window.Turbo.visit(data.url)
        } else {
          window.location.href = data.url
        }
      } else {
        // エラー
        alert(data.error || "投稿に失敗しました")
        this.submitButtonTarget.disabled = false
        this.submitButtonTarget.innerHTML = originalText
      }
    } catch (error) {
      console.error("Submit error:", error)
      alert("投稿に失敗しました")
      this.submitButtonTarget.disabled = false
      this.submitButtonTarget.innerHTML = originalText
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

  // 画像選択
  handleFileSelect(event) {
    const file = event.target.files[0]
    if (!file) return

    // ファイルサイズチェック（5MB）
    if (file.size > 5 * 1024 * 1024) {
      alert('ファイルサイズは5MB以下にしてください')
      return
    }

    // 画像をBase64に変換
    const reader = new FileReader()
    reader.onload = (e) => {
      this.selectedThumbnail = {
        key: 'custom',
        emoji: null,
        color: null,
        customImage: e.target.result
      }

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

      // 投稿ボタンの状態を更新
      this.updateSubmitButton()
    }
    reader.readAsDataURL(file)
  }

  // 画像をクリア
  clearImage(event) {
    event.preventDefault()
    event.stopPropagation()

    this.selectedThumbnail = { key: 'custom', emoji: null, color: null, customImage: null }

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

    // 投稿ボタンの状態を更新
    this.updateSubmitButton()
  }

  // コレクションプレビュー更新（アクションプランテキストのみ）
  updateCollectionPreview() {
    if (!this.hasPreviewActionPlanTarget) return

    const text = this.actionPlanInputTarget.value.trim() || 'アクションプランがここに表示されます'
    this.previewActionPlanTarget.textContent = text
  }

  // HTMLエスケープ
  escapeHtml(text) {
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  }
}
