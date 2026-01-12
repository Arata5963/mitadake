// app/javascript/controllers/ranking_tabs_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "list", "tabContainer"]

  connect() {
    // 初期状態で選択されているタブを取得
    this.currentPeriod = "all"
  }

  async switchTab(event) {
    const button = event.currentTarget
    const period = button.dataset.period

    // 既に選択中のタブなら何もしない
    if (period === this.currentPeriod) return

    this.currentPeriod = period

    // タブのスタイルを更新
    this.updateTabStyles(button)

    // ローディング状態を表示
    this.showLoading()

    try {
      // APIからデータを取得
      const response = await fetch(`/?user_ranking_period=${period}`, {
        headers: {
          "Accept": "text/html",
          "X-Requested-With": "XMLHttpRequest"
        }
      })

      if (response.ok) {
        const html = await response.text()
        // レスポンスからランキングリストを抽出して更新
        const parser = new DOMParser()
        const doc = parser.parseFromString(html, "text/html")
        const newList = doc.querySelector("#user-ranking-list")

        if (newList && this.hasListTarget) {
          this.listTarget.innerHTML = newList.innerHTML
        }
      }
    } catch (error) {
      console.error("ランキングの取得に失敗しました:", error)
    }
  }

  updateTabStyles(selectedButton) {
    // 全てのタブから選択状態を解除
    this.tabTargets.forEach(tab => {
      tab.classList.remove("bg-gray-900", "text-white")
      tab.classList.add("bg-gray-100", "text-gray-600", "hover:bg-gray-200")
    })

    // 選択されたタブに選択状態を付与
    selectedButton.classList.remove("bg-gray-100", "text-gray-600", "hover:bg-gray-200")
    selectedButton.classList.add("bg-gray-900", "text-white")
  }

  showLoading() {
    if (this.hasListTarget) {
      this.listTarget.innerHTML = `
        <div class="flex items-center justify-center py-8">
          <div class="animate-spin rounded-full h-6 w-6 border-2 border-gray-300 border-t-gray-900"></div>
        </div>
      `
    }
  }
}
