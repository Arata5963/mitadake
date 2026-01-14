// app/javascript/controllers/hero_video_controller.js
import { Controller } from "@hotwired/stimulus"

// ヒーロー動画の再生/一時停止コントローラー
export default class extends Controller {
  static targets = ["iframe", "playButton", "pauseButton"]
  static values = { videoId: String }

  connect() {
    this.player = null
    this.isPlaying = true
    this.loadYouTubeAPI()
  }

  // YouTube IFrame APIを読み込み
  loadYouTubeAPI() {
    if (window.YT && window.YT.Player) {
      this.initPlayer()
      return
    }

    // APIがまだ読み込まれていない場合
    if (!window.onYouTubeIframeAPIReady) {
      const tag = document.createElement("script")
      tag.src = "https://www.youtube.com/iframe_api"
      const firstScriptTag = document.getElementsByTagName("script")[0]
      firstScriptTag.parentNode.insertBefore(tag, firstScriptTag)
    }

    // API準備完了時のコールバック
    const originalCallback = window.onYouTubeIframeAPIReady
    window.onYouTubeIframeAPIReady = () => {
      if (originalCallback) originalCallback()
      this.initPlayer()
    }
  }

  // プレーヤーを初期化
  initPlayer() {
    const iframe = this.iframeTarget
    this.player = new YT.Player(iframe, {
      events: {
        onReady: () => {
          this.updateButtonState()
        },
        onStateChange: (event) => {
          this.isPlaying = event.data === YT.PlayerState.PLAYING
          this.updateButtonState()
        }
      }
    })
  }

  // 再生/一時停止トグル
  toggle() {
    if (!this.player) return

    if (this.isPlaying) {
      this.player.pauseVideo()
    } else {
      this.player.playVideo()
    }
  }

  // ボタン状態を更新
  updateButtonState() {
    if (this.hasPlayButtonTarget && this.hasPauseButtonTarget) {
      if (this.isPlaying) {
        this.playButtonTarget.classList.add("hidden")
        this.pauseButtonTarget.classList.remove("hidden")
      } else {
        this.playButtonTarget.classList.remove("hidden")
        this.pauseButtonTarget.classList.add("hidden")
      }
    }
  }
}
