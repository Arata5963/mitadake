// app/javascript/controllers/horizontal_scroll_controller.js
// ==========================================
// 横スクロールカルーセル制御コントローラー
// ==========================================
//
// 【このコントローラーの役割】
// カード一覧などを横スクロールで表示し、
// 左右の矢印ボタンでスクロールできるようにする。
//
// 【機能】
// - 左右の矢印ボタンでスクロール
// - スクロール位置に応じてボタンの表示/非表示を切り替え
// - モバイル（768px未満）では矢印ボタンを非表示
//   （スワイプで操作するため）
//
// 【使用場面】
// - ランキングカード一覧
// - チャンネル一覧
// - 動画カード一覧
//
// 【HTML側の使い方】
//   <div data-controller="horizontal-scroll">
//     <!-- 左矢印 -->
//     <button data-horizontal-scroll-target="leftBtn"
//             data-action="click->horizontal-scroll#scrollLeft">
//       ←
//     </button>
//
//     <!-- スクロールコンテナ -->
//     <div data-horizontal-scroll-target="container"
//          data-action="scroll->horizontal-scroll#onScroll">
//       <div>カード1</div>
//       <div>カード2</div>
//       <div>カード3</div>
//     </div>
//
//     <!-- 右矢印 -->
//     <button data-horizontal-scroll-target="rightBtn"
//             data-action="click->horizontal-scroll#scrollRight">
//       →
//     </button>
//   </div>
//

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // ------------------------------------------
  // Targets（操作する要素）
  // ------------------------------------------
  static targets = ["container", "leftBtn", "rightBtn"]

  // ------------------------------------------
  // connect: 初期化
  // ------------------------------------------
  // 【何をするメソッド？】
  // ページ読み込み時にボタンの表示状態を更新。
  // リサイズ時にも再計算するようイベントリスナーを登録。
  //
  connect() {
    // 少し遅延させてDOMが完全に描画されてから実行
    setTimeout(() => this.updateNavigation(), 100)

    // 画面リサイズ時にボタン表示を更新
    this.resizeHandler = () => this.updateNavigation()
    window.addEventListener("resize", this.resizeHandler)
  }

  // ------------------------------------------
  // disconnect: クリーンアップ
  // ------------------------------------------
  // 【何をするメソッド？】
  // イベントリスナーを解除してメモリリークを防ぐ。
  //
  disconnect() {
    if (this.resizeHandler) {
      window.removeEventListener("resize", this.resizeHandler)
    }
  }

  // ------------------------------------------
  // scrollRight: 右にスクロール
  // ------------------------------------------
  // 【何をするメソッド？】
  // カード2枚分（約440px）右にスムーズスクロール。
  //
  scrollRight() {
    if (this.hasContainerTarget) {
      const scrollAmount = 220  // カード幅200px + gap20px
      this.containerTarget.scrollBy({
        left: scrollAmount * 2,  // 2枚分スクロール
        behavior: "smooth"       // アニメーション付き
      })
    }
  }

  // ------------------------------------------
  // scrollLeft: 左にスクロール
  // ------------------------------------------
  // 【何をするメソッド？】
  // カード2枚分（約440px）左にスムーズスクロール。
  //
  scrollLeft() {
    if (this.hasContainerTarget) {
      const scrollAmount = 220
      this.containerTarget.scrollBy({
        left: -scrollAmount * 2,  // マイナス = 左方向
        behavior: "smooth"
      })
    }
  }

  // ------------------------------------------
  // onScroll: スクロール時の処理
  // ------------------------------------------
  // 【何をするメソッド？】
  // スクロール位置が変わった時にボタンの表示状態を更新。
  //
  // 【HTML側での呼び出し方】
  //   <div data-action="scroll->horizontal-scroll#onScroll">
  //
  onScroll() {
    this.updateNavigation()
  }

  // ------------------------------------------
  // updateNavigation: ボタンの表示状態を更新
  // ------------------------------------------
  // 【何をするメソッド？】
  // スクロール位置に応じて矢印ボタンの表示/非表示を切り替え。
  //
  // 【ロジック】
  // - 左端にいる → 左ボタンを隠す
  // - 右端にいる → 右ボタンを隠す
  // - モバイル → 両方隠す（スワイプ操作）
  //
  updateNavigation() {
    if (!this.hasContainerTarget) return

    // モバイル（768px未満）ではボタンを表示しない
    const isMobile = window.innerWidth < 768

    const container = this.containerTarget

    // スクロール関連の値を取得
    const scrollLeft = container.scrollLeft      // 現在のスクロール位置
    const scrollWidth = container.scrollWidth    // コンテンツ全体の幅
    const clientWidth = container.clientWidth    // 表示領域の幅
    const maxScroll = scrollWidth - clientWidth  // スクロール可能な最大値

    // スクロール可能かどうか判定（10pxのマージンを設ける）
    const canScrollLeft = scrollLeft > 10 && !isMobile
    const canScrollRight = scrollLeft < maxScroll - 10 && !isMobile

    // 左ボタンの表示/非表示
    if (this.hasLeftBtnTarget) {
      if (canScrollLeft) {
        this.leftBtnTarget.classList.remove("hidden")
        this.leftBtnTarget.classList.add("flex")
      } else {
        this.leftBtnTarget.classList.add("hidden")
        this.leftBtnTarget.classList.remove("flex")
      }
    }

    // 右ボタンの表示/非表示
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
