// app/javascript/controllers/horizontal_scroll_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "leftBtn", "rightBtn"]

  connect() {
    // 初期状態でボタンの表示を更新
    setTimeout(() => this.updateNavigation(), 100)

    // 画面リサイズ時にボタン表示を更新
    this.resizeHandler = () => this.updateNavigation()
    window.addEventListener("resize", this.resizeHandler)
  }

  disconnect() {
    // クリーンアップ
    if (this.resizeHandler) {
      window.removeEventListener("resize", this.resizeHandler)
    }
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

    // モバイル（768px未満）ではボタンを表示しない
    const isMobile = window.innerWidth < 768

    const container = this.containerTarget
    const scrollLeft = container.scrollLeft
    const scrollWidth = container.scrollWidth
    const clientWidth = container.clientWidth
    const maxScroll = scrollWidth - clientWidth

    const canScrollLeft = scrollLeft > 10 && !isMobile
    const canScrollRight = scrollLeft < maxScroll - 10 && !isMobile

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
