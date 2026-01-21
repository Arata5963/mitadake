// app/javascript/controllers/clipboard_controller.js
// ==========================================
// クリップボード自動検出コントローラー
// ==========================================
//
// 【このコントローラーの役割】
// 入力欄にフォーカスした時、クリップボードにYouTube URLがあれば
// 自動的に入力欄に貼り付ける便利機能。
//
// 【なぜこの機能が必要？】
// YouTubeアプリで「共有」→URLをコピー→このアプリに戻る
// という流れが多いため、自動で検出すると便利。
//
// 【HTML側の使い方】
//   <div data-controller="clipboard"
//        data-clipboard-url-value="">
//     <input type="text"
//            data-clipboard-target="input"
//            data-action="focus->clipboard#checkClipboard">
//   </div>
//
// 【Clipboard API について】
// navigator.clipboard.readText() でクリップボードの内容を読める。
// ただし、ユーザーの許可が必要（セキュリティ上の理由）。
// HTTPSでないと動作しない。
//

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // ------------------------------------------
  // Targets（操作する要素）
  // ------------------------------------------
  static targets = ["input"]

  // ------------------------------------------
  // Values（設定値）
  // ------------------------------------------
  static values = {
    // 既存のURL（編集時に設定される）
    // これがある場合は自動検出をスキップ
    url: String
  }

  // ------------------------------------------
  // connect: 初期化
  // ------------------------------------------
  // 【何をするメソッド？】
  // 編集モード（既存URLあり）の場合は自動検出をスキップ。
  // 新規作成時のみクリップボード検出が有効になる。
  //
  connect() {
    // 既存URLがある場合（編集時）は自動検出をスキップ
    if (this.urlValue && this.urlValue.length > 0) {
      return
    }
  }

  // ------------------------------------------
  // checkClipboard: クリップボードをチェック
  // ------------------------------------------
  // 【何をするメソッド？】
  // 入力欄にフォーカスした時に呼ばれる。
  // クリップボードにYouTube URLがあれば自動入力。
  //
  // 【HTML側での呼び出し方】
  //   <input data-action="focus->clipboard#checkClipboard">
  //
  async checkClipboard() {
    // 入力欄に既に値がある場合はスキップ
    // （ユーザーが入力中の内容を上書きしないため）
    if (this.inputTarget.value && this.inputTarget.value.length > 0) {
      return
    }

    try {
      // ------------------------------------------
      // クリップボードの読み取り
      // ------------------------------------------
      // await: 非同期処理の完了を待つ
      // navigator.clipboard.readText(): クリップボードのテキストを取得
      //
      const text = await navigator.clipboard.readText()

      // YouTube URLかどうかをチェック
      if (this.isYoutubeUrl(text)) {
        // 入力欄に設定
        this.inputTarget.value = text.trim()

        // 入力イベントを発火してフォームバリデーションを更新
        // bubbles: true → 親要素にもイベントが伝播する
        this.inputTarget.dispatchEvent(new Event("input", { bubbles: true }))
        this.inputTarget.dispatchEvent(new Event("change", { bubbles: true }))
      }
    } catch (error) {
      // クリップボードへのアクセスが拒否された場合
      // ブラウザの設定やHTTPSでない場合にエラーになる
      // エラーは無視して通常動作を継続
      console.debug("クリップボードへのアクセスが拒否されました:", error)
    }
  }

  // ------------------------------------------
  // isYoutubeUrl: YouTube URLかどうか判定
  // ------------------------------------------
  // 【何をするメソッド？】
  // 文字列がYouTube URLの形式かどうかをチェック。
  //
  // 【対応形式】
  // - https://www.youtube.com/watch?v=xxxxx
  // - https://youtu.be/xxxxx
  // - https://youtube.com/shorts/xxxxx
  //
  isYoutubeUrl(text) {
    if (!text) return false

    // YouTube URLのパターン（正規表現）
    const patterns = [
      /^(https?:\/\/)?(www\.)?youtube\.com\/watch\?v=[\w-]+/,  // 通常のURL
      /^(https?:\/\/)?(www\.)?youtu\.be\/[\w-]+/,              // 短縮URL
      /^(https?:\/\/)?(www\.)?youtube\.com\/shorts\/[\w-]+/    // Shorts
    ]

    // some: 1つでもマッチすればtrue
    return patterns.some(pattern => pattern.test(text.trim()))
  }
}
