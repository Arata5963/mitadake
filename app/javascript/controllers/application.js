// app/javascript/controllers/application.js
// ==========================================
// Stimulusアプリケーションの初期化
// ==========================================
//
// 【このファイルの役割】
// Stimulus（スティミュラス）フレームワークを起動し、
// 外部ライブラリを登録する設定ファイル。
// 全コントローラーの起点となる。
//
// 【Stimulusとは？】
// Hotwireの一部で、HTML要素に「振る舞い」を追加するフレームワーク。
// jQueryの代替として使われることが多い。
//
// HTMLで data-controller="xxx" と書くと、
// xxx_controller.js のコントローラーが自動的に紐づく。
//
// 【例】
//   <div data-controller="flash">
//     ↓
//   flash_controller.js の connect() が自動実行される
//
// 【設定内容】
// - Stimulusアプリケーションの起動
// - stimulus-autocomplete ライブラリの登録（検索フォーム用）
// - デバッグモードの設定（本番では false）
//

// ------------------------------------------
// Stimulusアプリケーションの起動
// ------------------------------------------
// Application.start() でStimulusを初期化。
// これにより data-controller 属性が有効になる。
//
import { Application } from "@hotwired/stimulus"

// ------------------------------------------
// 外部ライブラリの登録
// ------------------------------------------
// stimulus-autocomplete: 検索フォームのオートコンプリート機能
// https://github.com/afcapel/stimulus-autocomplete
//
import { Autocomplete } from "stimulus-autocomplete"

// Stimulusを起動
const application = Application.start()

// autocomplete コントローラーとして登録
// HTMLで data-controller="autocomplete" と書くと使える
application.register("autocomplete", Autocomplete)

// ------------------------------------------
// デバッグ設定
// ------------------------------------------
// true にすると、Stimulusの動作ログがコンソールに出力される
// 開発時に問題を調査する際に便利
//
application.debug = false

// グローバル変数として公開（デバッグ用）
// ブラウザの開発者ツールで window.Stimulus と打つとアクセスできる
window.Stimulus   = application

// 他のファイルから使えるようにエクスポート
export { application }
