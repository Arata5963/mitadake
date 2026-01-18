// app/javascript/controllers/flip_card_controller.js
import { Controller } from "@hotwired/stimulus"

// 表裏フリップカードコントローラー
export default class extends Controller {
  static targets = ["card"]

  connect() {
    this.flipped = false
  }

  toggle() {
    this.flipped = !this.flipped
    if (this.flipped) {
      this.cardTarget.style.transform = "rotateY(180deg)"
    } else {
      this.cardTarget.style.transform = "rotateY(0deg)"
    }
  }
}
