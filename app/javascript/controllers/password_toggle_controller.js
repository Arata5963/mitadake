// app/javascript/controllers/password_toggle_controller.js
// パスワード入力欄の表示/非表示切り替えコントローラー
//
// 使用例:
// <div data-controller="password-toggle">
//   <input type="password" data-password-toggle-target="input">
//   <button data-action="click->password-toggle#toggle">
//     <svg data-password-toggle-target="iconShow">目アイコン</svg>
//     <svg data-password-toggle-target="iconHide">非表示アイコン</svg>
//   </button>
// </div>

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "iconShow", "iconHide"]

  connect() {
    this.hidePassword()
  }

  toggle() {
    if (this.inputTarget.type === "password") {
      this.showPassword()
    } else {
      this.hidePassword()
    }
  }

  showPassword() {
    this.inputTarget.type = "text"
    this.iconShowTarget.classList.add("hidden")
    this.iconHideTarget.classList.remove("hidden")
  }

  hidePassword() {
    this.inputTarget.type = "password"
    this.iconShowTarget.classList.remove("hidden")
    this.iconHideTarget.classList.add("hidden")
  }
}
