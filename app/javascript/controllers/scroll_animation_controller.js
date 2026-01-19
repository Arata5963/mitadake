// app/javascript/controllers/scroll_animation_controller.js
import { Controller } from "@hotwired/stimulus"

// スクロールアニメーションコントローラー
// 要素が画面に入ったときにアニメーションを実行
export default class extends Controller {
  static values = {
    threshold: { type: Number, default: 0.1 },
    delay: { type: Number, default: 0 },
    duration: { type: Number, default: 600 },
    animation: { type: String, default: "fade-up" }
  }

  connect() {
    // 初期状態を設定
    this.element.style.opacity = "0"
    this.element.style.transition = `opacity ${this.durationValue}ms ease-out, transform ${this.durationValue}ms ease-out`

    // アニメーション種類に応じた初期位置
    this.setInitialPosition()

    // Intersection Observer を設定
    this.observer = new IntersectionObserver(
      (entries) => this.handleIntersect(entries),
      { threshold: this.thresholdValue, rootMargin: "0px 0px -50px 0px" }
    )

    this.observer.observe(this.element)
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }

  setInitialPosition() {
    switch (this.animationValue) {
      case "fade-up":
        this.element.style.transform = "translateY(40px)"
        break
      case "fade-down":
        this.element.style.transform = "translateY(-40px)"
        break
      case "fade-left":
        this.element.style.transform = "translateX(40px)"
        break
      case "fade-right":
        this.element.style.transform = "translateX(-40px)"
        break
      case "zoom-in":
        this.element.style.transform = "scale(0.9)"
        break
      case "fade":
      default:
        this.element.style.transform = "none"
        break
    }
  }

  handleIntersect(entries) {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        // 遅延を適用してアニメーション実行
        setTimeout(() => {
          this.element.style.opacity = "1"
          this.element.style.transform = "translateY(0) translateX(0) scale(1)"
        }, this.delayValue)

        // 一度だけ実行
        this.observer.unobserve(this.element)
      }
    })
  }
}
