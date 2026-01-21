// app/javascript/controllers/image_preview_controller.js
// ==========================================
// 画像プレビュー表示コントローラー
// ==========================================
//
// 【このコントローラーの役割】
// ファイル選択で画像を選んだ時に、
// アップロード前にプレビュー表示する。
//
// 【なぜプレビューが必要？】
// - ユーザーが選んだ画像を確認できる
// - 間違った画像を選んでしまっても、送信前に気づける
// - UX（ユーザー体験）の向上
//
// 【HTML側の使い方】
//   <div data-controller="image-preview">
//     <!-- ファイル選択 -->
//     <input type="file"
//            data-image-preview-target="input"
//            data-action="change->image-preview#preview">
//
//     <!-- プレビュー画像（最初は非表示） -->
//     <img data-image-preview-target="preview" class="hidden">
//
//     <!-- プレースホルダー（画像選択前に表示） -->
//     <div data-image-preview-target="placeholder">
//       画像を選択してください
//     </div>
//   </div>
//
// 【FileReaderとは？】
// ブラウザでファイルを読み込むためのAPIです。
// 画像をBase64形式（文字列）に変換して、
// <img src="..."> に設定できるようにします。
//

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // ------------------------------------------
  // Targets（操作する要素）
  // ------------------------------------------
  // - input: ファイル選択 <input type="file">
  // - preview: プレビュー表示用の <img> タグ
  // - placeholder: 画像選択前のプレースホルダー要素
  //
  static targets = ["input", "preview", "placeholder"]

  // ------------------------------------------
  // preview: 選択された画像をプレビュー表示
  // ------------------------------------------
  // 【何をするメソッド？】
  // ファイルが選択された時に呼ばれ、
  // 選択された画像をすぐにプレビュー表示する。
  //
  // 【HTML側での呼び出し方】
  //   <input type="file" data-action="change->image-preview#preview">
  //
  // 【処理の流れ】
  // 1. 選択されたファイルを取得
  // 2. FileReaderで読み込み
  // 3. 読み込み完了後、<img>のsrcに設定
  // 4. プレースホルダーを非表示
  //
  preview() {
    // 選択されたファイルを取得（複数選択の場合は最初の1つ）
    const file = this.inputTarget.files[0]

    if (file) {
      // ------------------------------------------
      // FileReaderでファイルを読み込む
      // ------------------------------------------
      // FileReader: ブラウザでファイルを非同期に読み込むAPI
      //
      const reader = new FileReader()

      // onload: 読み込み完了時のコールバック
      // e.target.result: 読み込んだデータ（Base64文字列）
      reader.onload = (e) => {
        // プレビュー画像を表示
        // Base64形式: data:image/jpeg;base64,/9j/4AAQ...
        this.previewTarget.src = e.target.result
        this.previewTarget.classList.remove("hidden")

        // プレースホルダーを非表示（存在する場合のみ）
        if (this.hasPlaceholderTarget) {
          this.placeholderTarget.classList.add("hidden")
        }
      }

      // 読み込みを開始（Data URL形式で読み込む）
      // readAsDataURL: ファイルをBase64文字列に変換
      reader.readAsDataURL(file)
    }
  }
}
