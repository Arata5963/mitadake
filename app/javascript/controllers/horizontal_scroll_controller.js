// 横スクロールカルーセル制御コントローラー
// カード一覧を左右矢印ボタンでスクロールする

import { Controller } from "@hotwired/stimulus"                // Stimulusコントローラー基底クラス

export default class extends Controller {
  static targets = ["container", "leftBtn", "rightBtn"]        // container: スクロール領域, leftBtn/rightBtn: 矢印

  // 初期化とリサイズ監視を設定
  connect() {
    setTimeout(() => this.updateNavigation(), 100)             // DOM描画後にボタン表示を更新
    this.resizeHandler = () => this.updateNavigation()         // リサイズハンドラーを保存
    window.addEventListener("resize", this.resizeHandler)
  }

  // リサイズ監視を解除
  disconnect() {
    if (this.resizeHandler) {
      window.removeEventListener("resize", this.resizeHandler)
    }
  }

  // 右に2枚分スクロール
  scrollRight() {
    if (this.hasContainerTarget) {
      const scrollAmount = 220                                 // カード幅200px + gap20px
      this.containerTarget.scrollBy({
        left: scrollAmount * 2,                                // 2枚分スクロール
        behavior: "smooth"                                     // アニメーション付き
      })
    }
  }

  // 左に2枚分スクロール
  scrollLeft() {
    if (this.hasContainerTarget) {
      const scrollAmount = 220
      this.containerTarget.scrollBy({
        left: -scrollAmount * 2,                               // マイナス = 左方向
        behavior: "smooth"
      })
    }
  }

  // スクロール位置変更時にボタン表示を更新
  onScroll() {
    this.updateNavigation()
  }

  // スクロール位置に応じて矢印ボタンの表示/非表示を切り替え
  updateNavigation() {
    if (!this.hasContainerTarget) return

    const isMobile = window.innerWidth < 768                   // モバイルではボタン非表示
    const container = this.containerTarget
    const scrollLeft = container.scrollLeft                    // 現在のスクロール位置
    const scrollWidth = container.scrollWidth                  // コンテンツ全体の幅
    const clientWidth = container.clientWidth                  // 表示領域の幅
    const maxScroll = scrollWidth - clientWidth                // スクロール可能な最大値
    const canScrollLeft = scrollLeft > 10 && !isMobile         // 左にスクロール可能か
    const canScrollRight = scrollLeft < maxScroll - 10 && !isMobile  // 右にスクロール可能か

    if (this.hasLeftBtnTarget) {                               // 左ボタンの表示制御
      if (canScrollLeft) {
        this.leftBtnTarget.classList.remove("hidden")
        this.leftBtnTarget.classList.add("flex")
      } else {
        this.leftBtnTarget.classList.add("hidden")
        this.leftBtnTarget.classList.remove("flex")
      }
    }

    if (this.hasRightBtnTarget) {                              // 右ボタンの表示制御
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
