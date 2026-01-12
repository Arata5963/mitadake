import { Controller } from "@hotwired/stimulus"

// マイページデザインパターン切り替え用コントローラー
export default class extends Controller {
  static targets = ["pattern"]

  connect() {
    // 初期状態でAパターンを表示
    this.showPattern("A")
  }

  switch(event) {
    const pattern = event.currentTarget.dataset.pattern
    this.showPattern(pattern)
    this.updateButtons(event.currentTarget)
  }

  showPattern(pattern) {
    this.patternTargets.forEach(el => {
      if (el.dataset.pattern === pattern) {
        el.classList.remove("hidden")
      } else {
        el.classList.add("hidden")
      }
    })
  }

  updateButtons(activeButton) {
    // すべてのボタンをリセット
    const buttons = this.element.querySelectorAll("[data-pattern]")
    buttons.forEach(btn => {
      btn.classList.remove("bg-gray-900", "text-white")
      btn.classList.add("bg-white", "border", "border-gray-200", "text-gray-700", "hover:bg-gray-100")
    })

    // アクティブボタンをハイライト
    activeButton.classList.remove("bg-white", "border", "border-gray-200", "text-gray-700", "hover:bg-gray-100")
    activeButton.classList.add("bg-gray-900", "text-white")
  }
}
