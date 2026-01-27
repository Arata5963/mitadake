// モバイル用サイドバー開閉コントローラー
// ハンバーガーメニュークリックで右からスライドインするサイドバーを制御

import { Controller } from "@hotwired/stimulus"                // Stimulusコントローラー基底クラス

export default class extends Controller {
  static targets = ["panel", "overlay"]                        // panel: サイドバー本体, overlay: 背景の幕

  // ESCキーリスナーを登録
  connect() {
    this.boundHandleKeydown = this.handleKeydown.bind(this)    // thisを固定
    document.addEventListener("keydown", this.boundHandleKeydown)
  }

  // ESCキーリスナーを解除
  disconnect() {
    document.removeEventListener("keydown", this.boundHandleKeydown)
  }

  // サイドバーをスライドインで表示
  open() {
    this.panelTarget.classList.remove("translate-x-full")      // 画面外から
    this.panelTarget.classList.add("translate-x-0")            // 画面内へ
    this.overlayTarget.classList.remove("opacity-0", "pointer-events-none")
    this.overlayTarget.classList.add("opacity-100", "pointer-events-auto")
    document.body.classList.add("overflow-hidden")             // 背景スクロール無効化
  }

  // サイドバーをスライドアウトで非表示
  close() {
    this.panelTarget.classList.remove("translate-x-0")         // 画面内から
    this.panelTarget.classList.add("translate-x-full")         // 画面外へ
    this.overlayTarget.classList.remove("opacity-100", "pointer-events-auto")
    this.overlayTarget.classList.add("opacity-0", "pointer-events-none")
    document.body.classList.remove("overflow-hidden")          // 背景スクロール有効化
  }

  // ESCキーで閉じる
  handleKeydown(event) {
    if (event.key === "Escape") {                              // ESCキーが押された場合
      this.close()
    }
  }
}
