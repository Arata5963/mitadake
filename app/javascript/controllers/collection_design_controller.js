// app/javascript/controllers/collection_design_controller.js
// ==========================================
// コレクションデザイン切り替えコントローラー
// ==========================================
//
// 【このコントローラーの役割】
// 動画一覧の表示デザインを切り替えるドロップダウンメニューを制御。
// 例: グリッド表示 ⇔ リスト表示
//
// 【HTML側の使い方】
//   <div data-controller="collection-design">
//     <div data-collection-design-target="dropdown">
//       <button data-action="click->collection-design#toggleMenu">
//         デザイン切替 ▼
//       </button>
//
//       <div data-collection-design-target="menu" class="hidden">
//         <a href="?design=grid">グリッド</a>
//         <a href="?design=list">リスト</a>
//       </div>
//     </div>
//   </div>
//

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // ------------------------------------------
  // Targets（操作する要素）
  // ------------------------------------------
  static targets = ["menu", "dropdown"]

  // ------------------------------------------
  // connect: 初期化
  // ------------------------------------------
  // 【何をするメソッド？】
  // ドロップダウン外クリックで閉じるイベントリスナーを登録。
  //
  connect() {
    // bind(this): イベントハンドラー内でthisが正しくコントローラーを指すように
    this.handleClickOutside = this.handleClickOutside.bind(this)
    document.addEventListener("click", this.handleClickOutside)
  }

  // ------------------------------------------
  // disconnect: クリーンアップ
  // ------------------------------------------
  // 【何をするメソッド？】
  // イベントリスナーを解除してメモリリークを防ぐ。
  //
  disconnect() {
    document.removeEventListener("click", this.handleClickOutside)
  }

  // ------------------------------------------
  // toggleMenu: メニューの開閉を切り替え
  // ------------------------------------------
  // 【何をするメソッド？】
  // ボタンクリックでドロップダウンメニューを開閉。
  //
  // 【HTML側での呼び出し方】
  //   <button data-action="click->collection-design#toggleMenu">
  //
  toggleMenu(event) {
    // stopPropagation: イベントの伝播を止める
    // これがないと、ボタンクリック → handleClickOutside も発火して
    // 開いた瞬間に閉じてしまう
    event.stopPropagation()

    // hidden クラスをトグル（あれば外す、なければ付ける）
    this.menuTarget.classList.toggle("hidden")
  }

  // ------------------------------------------
  // handleClickOutside: 外側クリックでメニューを閉じる
  // ------------------------------------------
  // 【何をするメソッド？】
  // ドロップダウン以外の場所をクリックしたらメニューを閉じる。
  // UXの改善（ユーザーが期待する動作）。
  //
  handleClickOutside(event) {
    // ドロップダウン要素を含まないクリックなら閉じる
    if (!this.dropdownTarget.contains(event.target)) {
      this.menuTarget.classList.add("hidden")
    }
  }
}
