// app/javascript/controllers/flash_controller.js
// ==========================================
// フラッシュメッセージ表示コントローラー
// ==========================================
//
// 【このコントローラーの役割】
// 画面上部に表示される通知メッセージ（成功、エラーなど）を制御。
// 一定時間後に自動で消える＋手動で閉じるボタンも対応。
//
// 【フラッシュメッセージとは？】
// 「保存しました」「エラーが発生しました」などの一時的な通知。
// Railsの flash[:notice] や flash[:alert] で設定される。
//
// 【HTML側の使い方】
//   <div data-controller="flash"
//        data-flash-remove-after-value="5000">
//     保存しました
//     <button data-action="click->flash#remove">✕</button>
//   </div>
//
// 【Stimulusの基本概念】
// - connect(): 要素がDOMに追加された時に実行される
// - disconnect(): 要素がDOMから削除された時に実行される
// - static values: コントローラーに渡すデータを定義
//

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // ------------------------------------------
  // Values（コントローラーに渡す値）
  // ------------------------------------------
  // HTML側で data-flash-remove-after-value="5000" のように設定
  //
  static values = {
    // 何ミリ秒後に自動削除するか（デフォルト: 5秒）
    removeAfter: { type: Number, default: 5000 }
  }

  // ------------------------------------------
  // connect: 要素が画面に表示された時
  // ------------------------------------------
  // 【何をするメソッド？】
  // タイマーをセットして、指定時間後に自動で消える。
  //
  connect() {
    // 指定時間後に自動で消える
    if (this.removeAfterValue > 0) {
      // setTimeout: 指定ミリ秒後に関数を実行
      // this.timeout に保存しておき、disconnect() でキャンセルできるようにする
      this.timeout = setTimeout(() => {
        this.remove()
      }, this.removeAfterValue)
    }
  }

  // ------------------------------------------
  // disconnect: 要素が画面から消えた時
  // ------------------------------------------
  // 【何をするメソッド？】
  // タイマーをキャンセルしてメモリリークを防ぐ。
  // 例: ユーザーが手動で閉じた後、タイマーが発火しないように
  //
  disconnect() {
    // タイムアウトをクリア（キャンセル）
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  }

  // ------------------------------------------
  // remove: メッセージを削除
  // ------------------------------------------
  // 【何をするメソッド？】
  // フェードアウトアニメーションを付けてから要素を削除。
  // ボタンクリックまたはタイマーで呼ばれる。
  //
  // 【HTML側での呼び出し方】
  //   <button data-action="click->flash#remove">✕</button>
  //
  remove() {
    // フェードアウトアニメーション用のCSSクラスを追加
    // Tailwind CSS のクラスを使用
    this.element.classList.add("opacity-0", "transition-opacity", "duration-300")

    // アニメーション完了後（300ms）に要素を完全に削除
    setTimeout(() => {
      this.element.remove()
    }, 300)
  }
}
