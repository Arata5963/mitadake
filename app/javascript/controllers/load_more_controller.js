// app/javascript/controllers/load_more_controller.js
// ==========================================
// 無限スクロール / もっと見るボタン制御
// ==========================================
//
// 【このコントローラーの役割】
// ページネーションを「もっと見る」ボタンに置き換え、
// 画面に余裕があれば自動で次のページを読み込む。
//
// 【動作パターン】
// 1. 画面にコンテンツが収まりきらない場合
//    → 「もっと見る」ボタンを表示
//
// 2. 画面に余裕がある場合
//    → 自動で次のページを読み込む（ユーザーがボタンを押す手間を省く）
//
// 【HTML側の使い方】
//   <div data-controller="load-more">
//     <!-- コンテンツコンテナ -->
//     <div data-load-more-target="container">
//       <div>アイテム1</div>
//       <div>アイテム2</div>
//     </div>
//
//     <!-- もっと見るボタン（Turbo Frameで次ページを読み込む） -->
//     <div data-load-more-target="button">
//       <a href="/posts?page=2" data-turbo-frame="_self">もっと見る</a>
//     </div>
//   </div>
//
// 【MutationObserver について】
// DOMの変化（要素の追加・削除など）を監視するAPI。
// Turbo Streamで新しいコンテンツが追加された時に検知できる。
//

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // ------------------------------------------
  // Targets（操作する要素）
  // ------------------------------------------
  static targets = ["button", "container"]

  // ------------------------------------------
  // connect: 初期化
  // ------------------------------------------
  // 【何をするメソッド？】
  // - 読み込み状態の初期化
  // - 画面に余裕があるかチェック
  // - DOM変更の監視を開始（Turbo Stream対応）
  //
  connect() {
    this.isLoading = false  // 読み込み中フラグ（二重読み込み防止）

    // 初回チェック
    this.checkAndLoad()

    // リサイズ時にもチェック
    this.resizeHandler = this.checkAndLoad.bind(this)
    window.addEventListener("resize", this.resizeHandler)

    // ------------------------------------------
    // DOM変更を監視（Turbo Stream対応）
    // ------------------------------------------
    // MutationObserver: DOMの変化を検知するAPI
    // Turbo Streamで新しいアイテムが追加された時に
    // 再度「まだ余裕があるか」をチェックする
    //
    this.observer = new MutationObserver(() => {
      setTimeout(() => {
        this.isLoading = false  // 読み込み完了
        this.checkAndLoad()     // 再度チェック
      }, 100)
    })

    if (this.hasContainerTarget) {
      // childList: 子要素の追加/削除を監視
      // subtree: 子孫要素も含めて監視
      this.observer.observe(this.containerTarget, { childList: true, subtree: true })
    }
  }

  // ------------------------------------------
  // disconnect: クリーンアップ
  // ------------------------------------------
  // 【何をするメソッド？】
  // イベントリスナーとObserverを解除。
  //
  disconnect() {
    window.removeEventListener("resize", this.resizeHandler)
    if (this.observer) {
      this.observer.disconnect()
    }
  }

  // ------------------------------------------
  // buttonTargetConnected: ボタンが追加された時
  // ------------------------------------------
  // 【何をするメソッド？】
  // Turbo Streamでボタンが動的に追加された時に呼ばれる。
  // Stimulusのライフサイクルコールバック。
  //
  buttonTargetConnected() {
    this.checkAndLoad()
  }

  // ------------------------------------------
  // checkAndLoad: 画面に余裕があれば自動読み込み
  // ------------------------------------------
  // 【何をするメソッド？】
  // コンテンツが画面に収まりきっているかチェックし、
  // 余裕があれば自動で次のページを読み込む。
  //
  checkAndLoad() {
    if (!this.hasButtonTarget || !this.hasContainerTarget) return

    const container = this.containerTarget
    const button = this.buttonTarget

    // ボタン内にリンクがあるかチェック（次ページがあるか）
    const loadMoreLink = button.querySelector("a")
    if (!loadMoreLink) {
      // 次ページがない場合はボタンを非表示
      button.classList.add("hidden")
      return
    }

    // コンテナの底がビューポートの底より下にあるかチェック
    const containerRect = container.getBoundingClientRect()
    const viewportHeight = window.innerHeight

    // フッターの高さを考慮（約80px）
    const footerHeight = 80
    const availableHeight = viewportHeight - footerHeight

    // コンテンツが画面に収まりきらない場合（スクロールが必要）
    const needsScroll = containerRect.bottom > availableHeight

    if (needsScroll) {
      // 画面いっぱい → ボタンを表示してユーザーに委ねる
      button.classList.remove("hidden")
    } else {
      // 画面に余裕あり → 自動で次を読み込み
      button.classList.add("hidden")

      // 二重読み込み防止
      if (!this.isLoading) {
        this.isLoading = true
        // リンクを自動クリック（Turbo Frameが次ページを読み込む）
        loadMoreLink.click()
      }
    }
  }
}
