// app/javascript/controllers/achievement_modal_controller.js
// 達成記録モーダルコントローラー
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
    this.selectedImage = null
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

  // 画像選択
  handleFileSelect(event) {
    const file = event.target.files[0]
    if (!file) return

    if (file.size > 5 * 1024 * 1024) {
      alert("ファイルサイズは5MB以下にしてください")
      return
    }

    const reader = new FileReader()
    reader.onload = (e) => {
      this.selectedImage = e.target.result
      this.showImagePreview(e.target.result)
    }
    reader.readAsDataURL(file)
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

    this.selectedImage = null

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
      const response = await fetch(this.achieveUrlValue, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-CSRF-Token": this.csrfToken()
        },
        body: JSON.stringify({
          reflection: reflection,
          result_image_data: this.selectedImage
        })
      })

      const data = await response.json()

      if (data.success) {
        this.close()
        window.location.reload()
      } else {
        alert(data.error || "達成処理に失敗しました")
        this.hideLoading()
      }
    } catch (error) {
      console.error("Achievement error:", error)
      alert("達成処理に失敗しました")
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
