import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "preview", "placeholder"]

  preview() {
    const file = this.inputTarget.files[0]
    if (file) {
      const reader = new FileReader()
      reader.onload = (e) => {
        // プレビュー画像を表示
        this.previewTarget.src = e.target.result
        this.previewTarget.classList.remove("hidden")
        // プレースホルダーを非表示
        if (this.hasPlaceholderTarget) {
          this.placeholderTarget.classList.add("hidden")
        }
      }
      reader.readAsDataURL(file)
    }
  }
}
