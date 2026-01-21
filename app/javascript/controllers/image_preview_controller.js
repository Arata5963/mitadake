// app/javascript/controllers/image_preview_controller.js
// 画像選択時のプレビュー表示コントローラー
//
// 使用例:
// <div data-controller="image-preview">
//   <input type="file" data-image-preview-target="input" data-action="change->image-preview#preview">
//   <img data-image-preview-target="preview" class="hidden">
//   <div data-image-preview-target="placeholder">プレースホルダー</div>
// </div>

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
