// app/javascript/controllers/password_toggle_controller.js
// ==========================================
// パスワード表示切り替えコントローラー
// ==========================================
//
// 【このコントローラーの役割】
// パスワード入力欄の「目のアイコン」ボタンを押すと、
// パスワードの表示/非表示（●●●● ⇔ password123）を切り替える。
//
// 【なぜこの機能が必要？】
// - ユーザーが入力したパスワードを確認したい時がある
// - スマホで入力ミスが多いため、確認できると便利
//
// 【HTML側の使い方】
//   <div data-controller="password-toggle">
//     <input type="password" data-password-toggle-target="input">
//
//     <button data-action="click->password-toggle#toggle">
//       <!-- 表示アイコン（目） -->
//       <svg data-password-toggle-target="iconShow">👁</svg>
//       <!-- 非表示アイコン（目に斜線） -->
//       <svg data-password-toggle-target="iconHide" class="hidden">👁‍🗨</svg>
//     </button>
//   </div>
//
// 【仕組み】
// - input.type = "password" → ●●●●で表示
// - input.type = "text" → そのまま表示
//

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // ------------------------------------------
  // Targets（操作する要素）
  // ------------------------------------------
  // - input: パスワード入力欄
  // - iconShow: 「表示する」アイコン（通常時表示）
  // - iconHide: 「非表示にする」アイコン（パスワード表示時に表示）
  //
  static targets = ["input", "iconShow", "iconHide"]

  // ------------------------------------------
  // connect: 初期化
  // ------------------------------------------
  // 【何をするメソッド？】
  // ページ読み込み時にパスワードを非表示状態にする。
  //
  connect() {
    this.hidePassword()
  }

  // ------------------------------------------
  // toggle: 表示/非表示を切り替え
  // ------------------------------------------
  // 【何をするメソッド？】
  // ボタンクリック時に表示状態を反転させる。
  //
  // 【HTML側での呼び出し方】
  //   <button data-action="click->password-toggle#toggle">
  //
  toggle() {
    // 現在の状態をチェックして切り替え
    if (this.inputTarget.type === "password") {
      this.showPassword()
    } else {
      this.hidePassword()
    }
  }

  // ------------------------------------------
  // showPassword: パスワードを表示
  // ------------------------------------------
  // 【何をするメソッド？】
  // 入力タイプを "text" に変更してパスワードを見える状態にする。
  // アイコンも「非表示アイコン」に切り替える。
  //
  showPassword() {
    // type="text" にすると入力内容がそのまま表示される
    this.inputTarget.type = "text"

    // アイコンを切り替え
    this.iconShowTarget.classList.add("hidden")     // 「表示」アイコンを隠す
    this.iconHideTarget.classList.remove("hidden")  // 「非表示」アイコンを表示
  }

  // ------------------------------------------
  // hidePassword: パスワードを非表示
  // ------------------------------------------
  // 【何をするメソッド？】
  // 入力タイプを "password" に変更して●●●●で隠す。
  //
  hidePassword() {
    // type="password" にすると入力内容が●●●●で隠される
    this.inputTarget.type = "password"

    // アイコンを切り替え
    this.iconShowTarget.classList.remove("hidden")  // 「表示」アイコンを表示
    this.iconHideTarget.classList.add("hidden")     // 「非表示」アイコンを隠す
  }
}
