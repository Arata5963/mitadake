import { Controller } from "@hotwired/stimulus"

// アコーディオン（折りたたみ）コントローラー
// 「他N件を表示」→「閉じる」のテキスト切り替え機能付き
export default class extends Controller {
  static targets = ["content", "icon", "text"]
  static values = {
    open: { type: Boolean, default: false },
    openText: { type: String, default: "閉じる" }
  }

  connect() {
    // 初期テキストを保存
    if (this.hasTextTarget) {
      this.closedText = this.textTarget.textContent
    }
    this.updateUI()
  }

  toggle() {
    this.openValue = !this.openValue
  }

  openValueChanged() {
    this.updateUI()
  }

  updateUI() {
    // コンテンツの表示/非表示
    if (this.hasContentTarget) {
      if (this.openValue) {
        this.contentTarget.classList.remove("hidden")
      } else {
        this.contentTarget.classList.add("hidden")
      }
    }

    // アイコンの回転
    if (this.hasIconTarget) {
      if (this.openValue) {
        this.iconTarget.style.transform = "rotate(180deg)"
      } else {
        this.iconTarget.style.transform = "rotate(0deg)"
      }
    }

    // テキストの切り替え
    if (this.hasTextTarget) {
      if (this.openValue) {
        this.textTarget.textContent = this.openTextValue
      } else {
        this.textTarget.textContent = this.closedText
      }
    }
  }
}
