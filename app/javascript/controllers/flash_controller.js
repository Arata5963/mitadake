// フラッシュメッセージ表示コントローラー
// 成功・エラー通知を一定時間後に自動で消す

import { Controller } from "@hotwired/stimulus"                // Stimulusコントローラー基底クラス

export default class extends Controller {
  static values = {
    removeAfter: { type: Number, default: 5000 }               // 自動削除までのミリ秒
  }

  // 画面表示時にタイマーをセット
  connect() {
    if (this.removeAfterValue > 0) {                           // 0より大きい場合のみ自動削除
      this.timeout = setTimeout(() => {                        // タイマーを保存
        this.remove()                                          // 指定時間後に削除
      }, this.removeAfterValue)
    }
  }

  // 画面から消えた時にタイマーをキャンセル
  disconnect() {
    if (this.timeout) {                                        // タイマーが存在する場合
      clearTimeout(this.timeout)                               // メモリリーク防止
    }
  }

  // フェードアウトして要素を削除
  remove() {
    this.element.classList.add("opacity-0", "transition-opacity", "duration-300")  // フェードアウト
    setTimeout(() => {                                         // アニメーション完了後
      this.element.remove()                                    // DOM要素を削除
    }, 300)
  }
}
