// app/javascript/controllers/horizontal_scroll_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "leftBtn", "rightBtn"]

  connect() {
    // 初期状態でボタンの表示を更新
    setTimeout(() => this.updateNavigation(), 100)
  }

  scrollRight() {
    if (this.hasContainerTarget) {
      const scrollAmount = 220 // カード幅200px + gap20px
      this.containerTarget.scrollBy({
        left: scrollAmount * 2,
        behavior: "smooth"
      })
    }
  }

  scrollLeft() {
    if (this.hasContainerTarget) {
      const scrollAmount = 220
      this.containerTarget.scrollBy({
        left: -scrollAmount * 2,
        behavior: "smooth"
      })
    }
  }

  onScroll() {
    this.updateNavigation()
  }

  updateNavigation() {
    if (!this.hasContainerTarget) return

    const container = this.containerTarget
    const scrollLeft = container.scrollLeft
    const scrollWidth = container.scrollWidth
    const clientWidth = container.clientWidth
    const maxScroll = scrollWidth - clientWidth

    const canScrollLeft = scrollLeft > 10
    const canScrollRight = scrollLeft < maxScroll - 10

    // 左ボタン
    if (this.hasLeftBtnTarget) {
      if (canScrollLeft) {
        this.leftBtnTarget.classList.remove("hidden")
        this.leftBtnTarget.classList.add("flex")
      } else {
        this.leftBtnTarget.classList.add("hidden")
        this.leftBtnTarget.classList.remove("flex")
      }
    }

    // 右ボタン
    if (this.hasRightBtnTarget) {
      if (canScrollRight) {
        this.rightBtnTarget.classList.remove("hidden")
        this.rightBtnTarget.classList.add("flex")
      } else {
        this.rightBtnTarget.classList.add("hidden")
        this.rightBtnTarget.classList.remove("flex")
      }
    }
  }
}
