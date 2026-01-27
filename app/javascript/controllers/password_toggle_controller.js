// パスワード表示切り替えコントローラー
// 目のアイコンクリックでパスワードの表示/非表示を切り替える

import { Controller } from "@hotwired/stimulus"                // Stimulusコントローラー基底クラス

export default class extends Controller {
  static targets = ["input", "iconShow", "iconHide"]           // input: パスワード欄, iconShow/Hide: アイコン

  // 初期状態は非表示
  connect() {
    this.hidePassword()
  }

  // 表示/非表示を切り替え
  toggle() {
    if (this.inputTarget.type === "password") {                // 現在非表示なら
      this.showPassword()                                      // 表示する
    } else {
      this.hidePassword()                                      // 非表示にする
    }
  }

  // パスワードを表示
  showPassword() {
    this.inputTarget.type = "text"                             // テキスト表示に変更
    this.iconShowTarget.classList.add("hidden")                // 「表示」アイコンを隠す
    this.iconHideTarget.classList.remove("hidden")             // 「非表示」アイコンを表示
  }

  // パスワードを非表示
  hidePassword() {
    this.inputTarget.type = "password"                         // マスク表示に変更
    this.iconShowTarget.classList.remove("hidden")             // 「表示」アイコンを表示
    this.iconHideTarget.classList.add("hidden")                // 「非表示」アイコンを隠す
  }
}
