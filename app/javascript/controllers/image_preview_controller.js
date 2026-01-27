// 画像プレビュー表示コントローラー
// ファイル選択時にアップロード前のプレビューを表示

import { Controller } from "@hotwired/stimulus"                // Stimulusコントローラー基底クラス

export default class extends Controller {
  static targets = ["input", "preview", "placeholder"]         // input: ファイル選択, preview: プレビュー画像

  // 選択された画像をプレビュー表示
  preview() {
    const file = this.inputTarget.files[0]                     // 選択されたファイルを取得

    if (file) {
      const reader = new FileReader()                          // ファイル読み込み用API

      reader.onload = (e) => {                                 // 読み込み完了時
        this.previewTarget.src = e.target.result               // Base64をsrcに設定
        this.previewTarget.classList.remove("hidden")          // プレビューを表示
        if (this.hasPlaceholderTarget) {                       // プレースホルダーがあれば
          this.placeholderTarget.classList.add("hidden")       // 非表示にする
        }
      }

      reader.readAsDataURL(file)                               // ファイルをBase64に変換して読み込み
    }
  }
}
