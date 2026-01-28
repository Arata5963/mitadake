// 達成記録モーダルコントローラー
// アクションプラン達成時に感想・記念写真を入力するモーダルを制御

import { Controller } from "@hotwired/stimulus"                // Stimulusコントローラー基底クラス

export default class extends Controller {
  static targets = [
    "overlay", "content", "reflectionInput", "reflectionDisplay",
    "imagePreview", "imageInput", "uploadArea", "clearImageBtn",
    "submitBtn", "editBtn", "loadingOverlay",
    "editImageInput", "editImagePreview", "displayImage", "editImageSection"
  ]

  static values = {
    entryId: Number,                                           // エントリーID
    postId: Number,                                            // 投稿ID
    mode: String,                                              // input/display
    achieveUrl: String,                                        // 達成記録APIのURL
    updateReflectionUrl: String,                               // 感想更新APIのURL
    deleteUrl: String,                                         // 削除APIのURL
    editUrl: String                                            // 編集ページURL
  }

  // モーダル表示時の初期化
  connect() {
    document.body.style.overflow = "hidden"                    // 背景スクロール無効化
    this.boundHandleKeydown = this.handleKeydown.bind(this)
    document.addEventListener("keydown", this.boundHandleKeydown)
    this.selectedFile = null                                   // 選択中のファイル（入力モード用）
    this.uploadedS3Key = null                                  // アップロード済みS3キー（入力モード用）
    this.editSelectedFile = null                               // 選択中のファイル（編集モード用）
    this.editUploadedS3Key = null                              // アップロード済みS3キー（編集モード用）
  }

  // モーダル非表示時のクリーンアップ
  disconnect() {
    document.body.style.overflow = ""                          // 背景スクロール有効化
    document.removeEventListener("keydown", this.boundHandleKeydown)
  }

  // ESCキーで閉じる
  handleKeydown(event) {
    if (event.key === "Escape") this.close()
  }

  // モーダルを閉じる
  close() {
    const container = document.getElementById("achievement_modal")
    if (container) container.innerHTML = ""
  }

  // オーバーレイクリックで閉じる
  closeOnOverlay(event) {
    if (event.target === event.currentTarget) this.close()
  }

  // ファイル選択ダイアログを開く
  triggerFileInput(event) {
    event.preventDefault()
    if (this.hasImageInputTarget) this.imageInputTarget.click()
  }

  // 画像選択時の処理
  handleFileSelect(event) {
    const file = event.target.files[0]
    if (!file) return

    if (file.size > 10 * 1024 * 1024) {                        // 10MB制限
      alert("ファイルサイズは10MB以下にしてください")
      return
    }

    this.selectedFile = file
    this.uploadedS3Key = null                                  // 新ファイル選択でリセット
    const previewUrl = URL.createObjectURL(file)               // ローカルプレビュー用URL
    this.showImagePreview(previewUrl)
  }

  // 画像プレビューを表示
  showImagePreview(dataUrl) {
    if (this.hasImagePreviewTarget) {
      this.imagePreviewTarget.src = dataUrl
      this.imagePreviewTarget.style.display = 'block'
    }
    if (this.hasUploadAreaTarget) this.uploadAreaTarget.style.display = 'none'
    if (this.hasClearImageBtnTarget) this.clearImageBtnTarget.style.display = 'flex'
  }

  // 画像をクリア
  clearImage(event) {
    event.preventDefault()
    event.stopPropagation()
    this.selectedFile = null
    this.uploadedS3Key = null
    if (this.hasImagePreviewTarget) {
      this.imagePreviewTarget.src = ""
      this.imagePreviewTarget.style.display = 'none'
    }
    if (this.hasUploadAreaTarget) this.uploadAreaTarget.style.display = 'flex'
    if (this.hasClearImageBtnTarget) this.clearImageBtnTarget.style.display = 'none'
    if (this.hasImageInputTarget) this.imageInputTarget.value = ""
  }

  // S3に直接アップロード（署名付きURL方式）
  async uploadToS3() {
    if (!this.selectedFile) return null
    if (this.uploadedS3Key) return this.uploadedS3Key          // アップロード済み

    const presignResponse = await fetch('/api/presigned_urls', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': this.csrfToken() },
      body: JSON.stringify({ filename: this.selectedFile.name, content_type: this.selectedFile.type })
    })

    if (!presignResponse.ok) throw new Error('署名付きURLの取得に失敗しました')
    const { upload_url, s3_key } = await presignResponse.json()

    const uploadResponse = await fetch(upload_url, {
      method: 'PUT',
      headers: { 'Content-Type': this.selectedFile.type },
      body: this.selectedFile
    })

    if (!uploadResponse.ok) throw new Error('S3へのアップロードに失敗しました')

    this.uploadedS3Key = s3_key
    return s3_key
  }

  // 達成を送信
  async submit(event) {
    event.preventDefault()

    if (!this.selectedFile) {                                  // 記念写真必須
      alert("記念写真を選択してください")
      return
    }

    const reflection = this.hasReflectionInputTarget ? this.reflectionInputTarget.value.trim() : ""
    if (!reflection) {                                         // 感想必須
      alert("感想を入力してください")
      if (this.hasReflectionInputTarget) this.reflectionInputTarget.focus()
      return
    }

    if (!confirm("達成を記録しますか？")) return

    this.showLoading()

    try {
      let s3Key = null
      if (this.selectedFile) s3Key = await this.uploadToS3()

      const response = await fetch(this.achieveUrlValue, {
        method: "PATCH",
        headers: { "Content-Type": "application/json", "Accept": "text/vnd.turbo-stream.html", "X-CSRF-Token": this.csrfToken() },
        body: JSON.stringify({ reflection: reflection, result_image_s3_key: s3Key })
      })

      if (response.ok) {
        this.close()
        sessionStorage.setItem('pendingFlash', JSON.stringify({ type: 'notice', message: '達成おめでとうございます！' }))
        window.location.reload()
      } else {
        const data = await response.json()
        alert(data.error || "達成処理に失敗しました")
        this.hideLoading()
      }
    } catch (error) {
      console.error("Achievement error:", error)
      alert(error.message || "達成処理に失敗しました")
      this.hideLoading()
    }
  }

  // 編集モードに切り替え
  switchToEdit() {
    if (this.hasReflectionDisplayTarget && this.hasReflectionInputTarget) {
      const currentReflection = this.reflectionDisplayTarget.textContent.trim()
      this.reflectionInputTarget.value = currentReflection === "（感想なし）" ? "" : currentReflection
      this.reflectionDisplayTarget.classList.add("hidden")
      this.reflectionInputTarget.classList.remove("hidden")
      this.reflectionInputTarget.focus()
    }
    if (this.hasEditImageSectionTarget) this.editImageSectionTarget.classList.remove("hidden")  // 画像変更ボタンを表示
    if (this.hasEditBtnTarget) {
      this.editBtnTarget.textContent = "保存"
      this.editBtnTarget.dataset.action = "click->achievement-modal#saveReflection"
    }
    this.editSelectedFile = null                               // 編集用ファイルをリセット
    this.editUploadedS3Key = null                              // 編集用S3キーをリセット
  }

  // 感想・画像を保存
  async saveReflection() {
    const reflection = this.hasReflectionInputTarget ? this.reflectionInputTarget.value.trim() : ""
    if (!reflection) {
      alert("感想を入力してください")
      if (this.hasReflectionInputTarget) this.reflectionInputTarget.focus()
      return
    }

    if (this.hasEditBtnTarget) {                               // 保存中表示
      this.editBtnTarget.textContent = "保存中..."
      this.editBtnTarget.disabled = true
    }

    try {
      let s3Key = null                                         // S3キー（画像変更時のみ）
      if (this.editSelectedFile) {                             // 新しい画像が選択されている場合
        s3Key = await this.uploadEditImageToS3()               // S3にアップロード
      }

      const body = { reflection: reflection }                  // リクエストボディ
      if (s3Key) body.result_image_s3_key = s3Key              // 画像があれば追加

      const response = await fetch(this.updateReflectionUrlValue, {
        method: "PATCH",
        headers: { "Content-Type": "application/json", "Accept": "application/json", "X-CSRF-Token": this.csrfToken() },
        body: JSON.stringify(body)
      })

      const data = await response.json()
      if (data.success) {
        if (this.hasReflectionDisplayTarget) {
          this.reflectionDisplayTarget.textContent = data.reflection || "（感想なし）"
          this.reflectionDisplayTarget.classList.remove("hidden")
        }
        if (this.hasReflectionInputTarget) this.reflectionInputTarget.classList.add("hidden")
        if (data.result_image_url && this.hasDisplayImageTarget) {  // 画像も更新された場合
          this.displayImageTarget.src = data.result_image_url       // 表示画像を更新
        }
        if (this.hasEditImagePreviewTarget) {                       // プレビューをリセット
          this.editImagePreviewTarget.classList.add("hidden")
          this.editImagePreviewTarget.src = ""
        }
        if (this.hasEditImageSectionTarget) this.editImageSectionTarget.classList.add("hidden")  // 変更ボタンを非表示
        if (this.hasEditBtnTarget) {
          this.editBtnTarget.textContent = "編集"
          this.editBtnTarget.disabled = false
          this.editBtnTarget.dataset.action = "click->achievement-modal#switchToEdit"
        }
        this.editSelectedFile = null                           // リセット
        this.editUploadedS3Key = null
      } else {
        alert(data.error || "保存に失敗しました")
        this.restoreEditButton()
      }
    } catch (error) {
      console.error("Save reflection error:", error)
      alert("保存に失敗しました")
      this.restoreEditButton()
    }
  }

  // 編集ボタンを元に戻す
  restoreEditButton() {
    if (this.hasEditBtnTarget) {
      this.editBtnTarget.textContent = "保存"
      this.editBtnTarget.disabled = false
    }
  }

  // 編集用画像をS3にアップロード
  async uploadEditImageToS3() {
    if (!this.editSelectedFile) return null
    if (this.editUploadedS3Key) return this.editUploadedS3Key  // アップロード済み

    const presignResponse = await fetch('/api/presigned_urls', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': this.csrfToken() },
      body: JSON.stringify({ filename: this.editSelectedFile.name, content_type: this.editSelectedFile.type })
    })

    if (!presignResponse.ok) throw new Error('署名付きURLの取得に失敗しました')
    const { upload_url, s3_key } = await presignResponse.json()

    const uploadResponse = await fetch(upload_url, {
      method: 'PUT',
      headers: { 'Content-Type': this.editSelectedFile.type },
      body: this.editSelectedFile
    })

    if (!uploadResponse.ok) throw new Error('S3へのアップロードに失敗しました')

    this.editUploadedS3Key = s3_key
    return s3_key
  }

  // 編集用画像選択時の処理
  handleEditFileSelect(event) {
    const file = event.target.files[0]
    if (!file) return

    if (file.size > 10 * 1024 * 1024) {                        // 10MB制限
      alert("ファイルサイズは10MB以下にしてください")
      return
    }

    this.editSelectedFile = file
    this.editUploadedS3Key = null                              // 新ファイル選択でリセット
    const previewUrl = URL.createObjectURL(file)               // ローカルプレビュー用URL
    this.showEditImagePreview(previewUrl)
  }

  // 編集用画像プレビューを表示
  showEditImagePreview(dataUrl) {
    if (this.hasEditImagePreviewTarget) {
      this.editImagePreviewTarget.src = dataUrl
      this.editImagePreviewTarget.classList.remove('hidden')     // プレビューを表示（元画像の上に重ねる）
    }
  }

  // 編集用画像をクリア（プレビューを元に戻す）
  clearEditImage(event) {
    event.preventDefault()
    event.stopPropagation()
    this.editSelectedFile = null
    this.editUploadedS3Key = null
    if (this.hasEditImagePreviewTarget) {
      this.editImagePreviewTarget.src = ""
      this.editImagePreviewTarget.classList.add('hidden')        // プレビューを非表示
    }
    if (this.hasEditImageInputTarget) this.editImageInputTarget.value = ""
  }

  // 編集用ファイル選択ダイアログを開く
  triggerEditFileInput(event) {
    event.preventDefault()
    if (this.hasEditImageInputTarget) this.editImageInputTarget.click()
  }

  // 編集ページへ移動
  goToEdit(event) {
    event.preventDefault()
    event.stopPropagation()
    const url = event.currentTarget.dataset.editUrl || this.editUrlValue
    if (url && url !== 'undefined' && url !== '') window.location.href = url
  }

  // エントリーを削除
  async deleteEntry() {
    if (!confirm("このアクションプランを削除しますか？この操作は取り消せません。")) return

    try {
      const deleteUrl = this.deleteUrlValue || `/posts/${this.postIdValue}/post_entries/${this.entryIdValue}`
      const response = await fetch(deleteUrl, {
        method: "DELETE",
        headers: { "Accept": "text/vnd.turbo-stream.html", "X-CSRF-Token": this.csrfToken() }
      })

      if (response.ok) {
        this.close()
        window.location.reload()
      } else {
        alert("削除に失敗しました")
      }
    } catch (error) {
      console.error("Delete error:", error)
      alert("削除に失敗しました")
    }
  }

  // ローディング表示
  showLoading() {
    if (this.hasLoadingOverlayTarget) {
      this.loadingOverlayTarget.classList.remove("hidden")
      this.loadingOverlayTarget.classList.add("flex")
    }
    if (this.hasSubmitBtnTarget) this.submitBtnTarget.disabled = true
  }

  // ローディング非表示
  hideLoading() {
    if (this.hasLoadingOverlayTarget) {
      this.loadingOverlayTarget.classList.add("hidden")
      this.loadingOverlayTarget.classList.remove("flex")
    }
    if (this.hasSubmitBtnTarget) this.submitBtnTarget.disabled = false
  }

  // CSRFトークンを取得
  csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content
  }
}
