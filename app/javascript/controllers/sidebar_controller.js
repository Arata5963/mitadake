// app/javascript/controllers/sidebar_controller.js
// ==========================================
// モバイル用サイドバー開閉コントローラー
// ==========================================
//
// 【このコントローラーの役割】
// モバイル画面でハンバーガーメニューを押した時に
// 画面右から滑り出すサイドバーを制御する。
//
// 【機能】
// - サイドバーのスライドイン/アウト
// - オーバーレイ（背景の黒い幕）の表示/非表示
// - ESCキーで閉じる
// - 開いている間はbodyのスクロールを無効化
//
// 【HTML側の使い方】
//   <div data-controller="sidebar">
//     <!-- ハンバーガーボタン -->
//     <button data-action="click->sidebar#open">☰</button>
//
//     <!-- オーバーレイ（背景クリックで閉じる） -->
//     <div data-sidebar-target="overlay"
//          data-action="click->sidebar#close"></div>
//
//     <!-- サイドバー本体 -->
//     <div data-sidebar-target="panel">
//       メニュー内容
//     </div>
//   </div>
//
// 【Stimulusのtargetsとは？】
// HTML要素をJavaScriptから参照するための仕組み。
// data-sidebar-target="panel" と書くと、
// this.panelTarget でその要素にアクセスできる。
//

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // ------------------------------------------
  // Targets（HTML要素の参照）
  // ------------------------------------------
  // - panel: サイドバー本体
  // - overlay: 背景の半透明オーバーレイ
  //
  static targets = ["panel", "overlay"]

  // ------------------------------------------
  // connect: コントローラーがDOMに接続された時
  // ------------------------------------------
  // 【何をするメソッド？】
  // ESCキーのイベントリスナーを登録。
  //
  connect() {
    // bind(this): イベントハンドラー内で this がコントローラーを指すようにする
    this.boundHandleKeydown = this.handleKeydown.bind(this)
    document.addEventListener("keydown", this.boundHandleKeydown)
  }

  // ------------------------------------------
  // disconnect: コントローラーがDOMから切り離された時
  // ------------------------------------------
  // 【何をするメソッド？】
  // イベントリスナーを解除してメモリリークを防ぐ。
  //
  disconnect() {
    document.removeEventListener("keydown", this.boundHandleKeydown)
  }

  // ------------------------------------------
  // open: サイドバーを開く
  // ------------------------------------------
  // 【何をするメソッド？】
  // サイドバーを画面右からスライドインさせる。
  //
  // 【HTML側での呼び出し方】
  //   <button data-action="click->sidebar#open">☰</button>
  //
  open() {
    // サイドバーを開く（Tailwind CSSのクラス操作）
    // translate-x-full: 画面外（右）
    // translate-x-0: 画面内（表示）
    this.panelTarget.classList.remove("translate-x-full")
    this.panelTarget.classList.add("translate-x-0")

    // オーバーレイを表示
    // opacity-0: 透明
    // opacity-100: 不透明
    this.overlayTarget.classList.remove("opacity-0", "pointer-events-none")
    this.overlayTarget.classList.add("opacity-100", "pointer-events-auto")

    // bodyのスクロールを無効化（サイドバー開いてる間は背景スクロールさせない）
    document.body.classList.add("overflow-hidden")
  }

  // ------------------------------------------
  // close: サイドバーを閉じる
  // ------------------------------------------
  // 【何をするメソッド？】
  // サイドバーを画面外にスライドアウトさせる。
  //
  // 【呼ばれるタイミング】
  // - オーバーレイをクリック
  // - ESCキーを押す
  // - 閉じるボタンをクリック
  //
  close() {
    // サイドバーを閉じる
    this.panelTarget.classList.remove("translate-x-0")
    this.panelTarget.classList.add("translate-x-full")

    // オーバーレイを非表示
    this.overlayTarget.classList.remove("opacity-100", "pointer-events-auto")
    this.overlayTarget.classList.add("opacity-0", "pointer-events-none")

    // bodyのスクロールを有効化
    document.body.classList.remove("overflow-hidden")
  }

  // ------------------------------------------
  // handleKeydown: キーボードイベント処理
  // ------------------------------------------
  // 【何をするメソッド？】
  // ESCキーが押されたらサイドバーを閉じる。
  //
  handleKeydown(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }
}
