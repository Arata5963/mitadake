// app/javascript/controllers/achievement_modal_controller.js
// ==========================================
// 達成記録モーダルコントローラー
// ==========================================
//
// 【このコントローラーの役割】
// アクションプランを「達成」する時に表示されるモーダルを制御。
// 感想入力と記念写真のアップロードができる。
//
// 【2つのモード】
// 1. input モード: 新しく達成を記録する（感想・画像を入力）
// 2. display モード: 既存の達成記録を閲覧する
//
// 【処理フロー（input モード）】
//
//   1. モーダルが開く
//      ↓
//   2. 感想を入力（必須）
//      ↓
//   3. 記念写真を選択（任意）
//      ↓
//   4. 送信
//      - 画像があればS3にアップロード
//      - サーバーに達成を記録
//      ↓
//   5. モーダルを閉じてページ更新
//
// 【HTML構造】
// achievement_card_controller から動的にHTMLが挿入される。
// モーダルのHTMLはJavaScriptで生成（buildInputModalHtml等）。
//
// 【S3アップロード】
// 署名付きURL方式で直接S3にアップロード。
// サーバーを経由しないので高速。
//

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "overlay",
    "content",
    "reflectionInput",
    "reflectionDisplay",
    "imagePreview",
    "imageInput",
    "uploadArea",
    "clearImageBtn",
    "submitBtn",
    "editBtn",
    "loadingOverlay"
  ]

  static values = {
    entryId: Number,
    postId: Number,
    mode: String,
    achieveUrl: String,
    updateReflectionUrl: String
  }

  connect() {
    document.body.style.overflow = "hidden"
    this.boundHandleKeydown = this.handleKeydown.bind(this)
    document.addEventListener("keydown", this.boundHandleKeydown)
    this.selectedFile = null      // Fileオブジェクトを保持
    this.uploadedS3Key = null     // アップロード後のS3キー
  }

  disconnect() {
    document.body.style.overflow = ""
    document.removeEventListener("keydown", this.boundHandleKeydown)
  }

  handleKeydown(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }

  close() {
    const container = document.getElementById("achievement_modal")
    if (container) {
      container.innerHTML = ""
    }
  }

  closeOnOverlay(event) {
    if (event.target === event.currentTarget) {
      this.close()
    }
  }

  // ファイル選択をトリガー
  triggerFileInput(event) {
    event.preventDefault()
    if (this.hasImageInputTarget) {
      this.imageInputTarget.click()
    }
  }

  // 画像選択（署名付きURL方式：Base64変換しない）
  handleFileSelect(event) {
    const file = event.target.files[0]
    if (!file) return

    if (file.size > 5 * 1024 * 1024) {
      alert("ファイルサイズは5MB以下にしてください")
      return
    }

    // ファイルを保持（Base64変換しない）
    this.selectedFile = file
    this.uploadedS3Key = null  // 新しいファイルが選択されたらリセット

    // プレビュー表示（ローカルURL使用）
    const previewUrl = URL.createObjectURL(file)
    this.showImagePreview(previewUrl)
  }

  showImagePreview(dataUrl) {
    // 画像を表示
    if (this.hasImagePreviewTarget) {
      this.imagePreviewTarget.src = dataUrl
      this.imagePreviewTarget.style.display = 'block'
    }
    // アップロードエリアを非表示
    if (this.hasUploadAreaTarget) {
      this.uploadAreaTarget.style.display = 'none'
    }
    // ×ボタンを表示
    if (this.hasClearImageBtnTarget) {
      this.clearImageBtnTarget.style.display = 'flex'
    }
  }

  clearImage(event) {
    event.preventDefault()
    event.stopPropagation()

    this.selectedFile = null
    this.uploadedS3Key = null

    // 画像を非表示
    if (this.hasImagePreviewTarget) {
      this.imagePreviewTarget.src = ""
      this.imagePreviewTarget.style.display = 'none'
    }
    // アップロードエリアを表示
    if (this.hasUploadAreaTarget) {
      this.uploadAreaTarget.style.display = 'flex'
    }
    // ×ボタンを非表示
    if (this.hasClearImageBtnTarget) {
      this.clearImageBtnTarget.style.display = 'none'
    }
    // ファイル入力をリセット
    if (this.hasImageInputTarget) {
      this.imageInputTarget.value = ""
    }
  }

  // S3に直接アップロード（署名付きURL方式）
  async uploadToS3() {
    if (!this.selectedFile) return null
    if (this.uploadedS3Key) return this.uploadedS3Key  // 既にアップロード済み

    // 1. 署名付きURLを取得
    const presignResponse = await fetch('/api/presigned_urls', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': this.csrfToken()
      },
      body: JSON.stringify({
        filename: this.selectedFile.name,
        content_type: this.selectedFile.type
      })
    })

    if (!presignResponse.ok) {
      throw new Error('署名付きURLの取得に失敗しました')
    }

    const { upload_url, s3_key } = await presignResponse.json()

    // 2. S3に直接PUT
    const uploadResponse = await fetch(upload_url, {
      method: 'PUT',
      headers: {
        'Content-Type': this.selectedFile.type
      },
      body: this.selectedFile
    })

    if (!uploadResponse.ok) {
      throw new Error('S3へのアップロードに失敗しました')
    }

    this.uploadedS3Key = s3_key
    return s3_key
  }

  // 達成送信
  async submit(event) {
    event.preventDefault()

    const reflection = this.hasReflectionInputTarget
      ? this.reflectionInputTarget.value.trim()
      : ""

    // 感想は必須
    if (!reflection) {
      alert("感想を入力してください")
      if (this.hasReflectionInputTarget) {
        this.reflectionInputTarget.focus()
      }
      return
    }

    this.showLoading()

    try {
      // 1. 画像がある場合はS3に直接アップロード
      let s3Key = null
      if (this.selectedFile) {
        s3Key = await this.uploadToS3()
      }

      // 2. 達成を記録（Turbo Streamで送信）
      const response = await fetch(this.achieveUrlValue, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "Accept": "text/vnd.turbo-stream.html",
          "X-CSRF-Token": this.csrfToken()
        },
        body: JSON.stringify({
          reflection: reflection,
          result_image_s3_key: s3Key
        })
      })

      if (response.ok) {
        // Turbo Streamレスポンスを処理
        const html = await response.text()
        Turbo.renderStreamMessage(html)
        this.close()
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

    if (this.hasEditBtnTarget) {
      this.editBtnTarget.textContent = "保存"
      this.editBtnTarget.dataset.action = "click->achievement-modal#saveReflection"
    }
  }

  // 感想を保存
  async saveReflection() {
    const reflection = this.hasReflectionInputTarget
      ? this.reflectionInputTarget.value.trim()
      : ""

    // 感想は必須
    if (!reflection) {
      alert("感想を入力してください")
      if (this.hasReflectionInputTarget) {
        this.reflectionInputTarget.focus()
      }
      return
    }

    try {
      const response = await fetch(this.updateReflectionUrlValue, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-CSRF-Token": this.csrfToken()
        },
        body: JSON.stringify({ reflection: reflection })
      })

      const data = await response.json()

      if (data.success) {
        if (this.hasReflectionDisplayTarget) {
          this.reflectionDisplayTarget.textContent = data.reflection || "（感想なし）"
          this.reflectionDisplayTarget.classList.remove("hidden")
        }
        if (this.hasReflectionInputTarget) {
          this.reflectionInputTarget.classList.add("hidden")
        }
        if (this.hasEditBtnTarget) {
          this.editBtnTarget.textContent = "編集"
          this.editBtnTarget.dataset.action = "click->achievement-modal#switchToEdit"
        }
      } else {
        alert(data.error || "保存に失敗しました")
      }
    } catch (error) {
      console.error("Save reflection error:", error)
      alert("保存に失敗しました")
    }
  }

  showLoading() {
    if (this.hasLoadingOverlayTarget) {
      this.loadingOverlayTarget.classList.remove("hidden")
      this.loadingOverlayTarget.classList.add("flex")
    }
    if (this.hasSubmitBtnTarget) {
      this.submitBtnTarget.disabled = true
    }
  }

  hideLoading() {
    if (this.hasLoadingOverlayTarget) {
      this.loadingOverlayTarget.classList.add("hidden")
      this.loadingOverlayTarget.classList.remove("flex")
    }
    if (this.hasSubmitBtnTarget) {
      this.submitBtnTarget.disabled = false
    }
  }

  csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content
  }

}
