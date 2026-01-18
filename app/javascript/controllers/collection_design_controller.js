// app/javascript/controllers/collection_design_controller.js
import { Controller } from "@hotwired/stimulus"

// コレクションデザイン切り替えコントローラー
export default class extends Controller {
  static targets = ["menu", "dropdown"]

  connect() {
    this.handleClickOutside = this.handleClickOutside.bind(this)
    document.addEventListener("click", this.handleClickOutside)
  }

  disconnect() {
    document.removeEventListener("click", this.handleClickOutside)
  }

  toggleMenu(event) {
    event.stopPropagation()
    this.menuTarget.classList.toggle("hidden")
  }

  handleClickOutside(event) {
    if (!this.dropdownTarget.contains(event.target)) {
      this.menuTarget.classList.add("hidden")
    }
  }
}
