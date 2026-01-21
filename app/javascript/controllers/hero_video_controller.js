// app/javascript/controllers/hero_video_controller.js
// ==========================================
// ヒーロー動画再生制御コントローラー
// ==========================================
//
// 【このコントローラーの役割】
// トップページなどに表示される大きなYouTube動画（ヒーロー動画）の
// 再生/一時停止を制御する。
//
// 【YouTube IFrame API について】
// YouTubeが提供するJavaScript API。
// 埋め込み動画を JavaScript から制御できる。
// - 再生/一時停止
// - 音量調整
// - 再生位置の取得
// など
//
// 【HTML側の使い方】
//   <div data-controller="hero-video"
//        data-hero-video-video-id-value="dQw4w9WgXcQ">
//
//     <iframe data-hero-video-target="iframe"
//             src="https://www.youtube.com/embed/dQw4w9WgXcQ?enablejsapi=1">
//     </iframe>
//
//     <button data-action="click->hero-video#toggle">
//       <span data-hero-video-target="playButton">▶</span>
//       <span data-hero-video-target="pauseButton">⏸</span>
//     </button>
//   </div>
//
// 【重要】enablejsapi=1 パラメータが必須！
//

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // ------------------------------------------
  // Targets & Values
  // ------------------------------------------
  static targets = ["iframe", "playButton", "pauseButton"]
  static values = { videoId: String }

  // ------------------------------------------
  // connect: 初期化
  // ------------------------------------------
  // 【何をするメソッド？】
  // YouTube IFrame APIを読み込んでプレーヤーを初期化。
  //
  connect() {
    this.player = null      // YouTubeプレーヤーオブジェクト
    this.isPlaying = true   // 再生中かどうか
    this.loadYouTubeAPI()
  }

  // ------------------------------------------
  // loadYouTubeAPI: YouTube IFrame APIを読み込み
  // ------------------------------------------
  // 【何をするメソッド？】
  // YouTubeのAPIスクリプトを動的に読み込む。
  // 既に読み込み済みなら即座にプレーヤーを初期化。
  //
  loadYouTubeAPI() {
    // 既にAPIが読み込まれている場合
    if (window.YT && window.YT.Player) {
      this.initPlayer()
      return
    }

    // APIがまだ読み込まれていない場合、スクリプトを追加
    if (!window.onYouTubeIframeAPIReady) {
      const tag = document.createElement("script")
      tag.src = "https://www.youtube.com/iframe_api"
      const firstScriptTag = document.getElementsByTagName("script")[0]
      firstScriptTag.parentNode.insertBefore(tag, firstScriptTag)
    }

    // API準備完了時のコールバックを設定
    const originalCallback = window.onYouTubeIframeAPIReady
    window.onYouTubeIframeAPIReady = () => {
      // 既存のコールバックがあれば先に実行
      if (originalCallback) originalCallback()
      this.initPlayer()
    }
  }

  // ------------------------------------------
  // initPlayer: プレーヤーを初期化
  // ------------------------------------------
  // 【何をするメソッド？】
  // YT.Player オブジェクトを作成し、
  // 既存のiframeと紐づける。
  //
  initPlayer() {
    const iframe = this.iframeTarget

    // YT.Player: YouTubeプレーヤーを制御するオブジェクト
    this.player = new YT.Player(iframe, {
      events: {
        // 準備完了時
        onReady: () => {
          this.updateButtonState()
        },
        // 状態変化時（再生開始、一時停止など）
        onStateChange: (event) => {
          // YT.PlayerState.PLAYING = 1
          this.isPlaying = event.data === YT.PlayerState.PLAYING
          this.updateButtonState()
        }
      }
    })
  }

  // ------------------------------------------
  // toggle: 再生/一時停止を切り替え
  // ------------------------------------------
  // 【何をするメソッド？】
  // ボタンクリックで再生⇔一時停止をトグル。
  //
  toggle() {
    if (!this.player) return

    if (this.isPlaying) {
      this.player.pauseVideo()  // 一時停止
    } else {
      this.player.playVideo()   // 再生
    }
  }

  // ------------------------------------------
  // updateButtonState: ボタン状態を更新
  // ------------------------------------------
  // 【何をするメソッド？】
  // 再生中かどうかでボタンのアイコンを切り替え。
  //
  updateButtonState() {
    if (this.hasPlayButtonTarget && this.hasPauseButtonTarget) {
      if (this.isPlaying) {
        // 再生中 → 一時停止ボタンを表示
        this.playButtonTarget.classList.add("hidden")
        this.pauseButtonTarget.classList.remove("hidden")
      } else {
        // 一時停止中 → 再生ボタンを表示
        this.playButtonTarget.classList.remove("hidden")
        this.pauseButtonTarget.classList.add("hidden")
      }
    }
  }
}
