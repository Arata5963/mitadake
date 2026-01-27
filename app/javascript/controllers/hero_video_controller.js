// ヒーロー動画再生制御コントローラー
// トップページのYouTube動画の再生/一時停止を制御

import { Controller } from "@hotwired/stimulus"                // Stimulusコントローラー基底クラス

export default class extends Controller {
  static targets = ["iframe", "playButton", "pauseButton"]     // iframe: YouTube埋め込み, ボタン類
  static values = { videoId: String }                          // YouTube動画ID

  // YouTube IFrame APIを読み込んで初期化
  connect() {
    this.player = null                                         // YouTubeプレーヤーオブジェクト
    this.isPlaying = true                                      // 再生中フラグ
    this.loadYouTubeAPI()
  }

  // YouTube IFrame APIスクリプトを読み込み
  loadYouTubeAPI() {
    if (window.YT && window.YT.Player) {                       // 既にAPI読み込み済み
      this.initPlayer()
      return
    }

    if (!window.onYouTubeIframeAPIReady) {                     // スクリプトタグを追加
      const tag = document.createElement("script")
      tag.src = "https://www.youtube.com/iframe_api"
      const firstScriptTag = document.getElementsByTagName("script")[0]
      firstScriptTag.parentNode.insertBefore(tag, firstScriptTag)
    }

    const originalCallback = window.onYouTubeIframeAPIReady    // 既存のコールバックを保存
    window.onYouTubeIframeAPIReady = () => {
      if (originalCallback) originalCallback()                 // 既存コールバックを先に実行
      this.initPlayer()
    }
  }

  // YT.Playerオブジェクトを作成
  initPlayer() {
    const iframe = this.iframeTarget
    this.player = new YT.Player(iframe, {
      events: {
        onReady: () => {                                       // 準備完了時
          this.updateButtonState()
        },
        onStateChange: (event) => {                            // 状態変化時
          this.isPlaying = event.data === YT.PlayerState.PLAYING
          this.updateButtonState()
        }
      }
    })
  }

  // 再生/一時停止を切り替え
  toggle() {
    if (!this.player) return
    if (this.isPlaying) {
      this.player.pauseVideo()                                 // 一時停止
    } else {
      this.player.playVideo()                                  // 再生
    }
  }

  // ボタンの表示状態を更新
  updateButtonState() {
    if (this.hasPlayButtonTarget && this.hasPauseButtonTarget) {
      if (this.isPlaying) {                                    // 再生中は一時停止ボタンを表示
        this.playButtonTarget.classList.add("hidden")
        this.pauseButtonTarget.classList.remove("hidden")
      } else {                                                 // 一時停止中は再生ボタンを表示
        this.playButtonTarget.classList.remove("hidden")
        this.pauseButtonTarget.classList.add("hidden")
      }
    }
  }
}
