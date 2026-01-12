// app/javascript/controllers/ai_suggestions_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["loading", "list"]
  static values = { url: String }

  // ページ読み込み時に自動で提案を取得
  connect() {
    this.fetch()
  }

  async fetch() {
    // ローディングを表示
    this.loadingTarget.style.display = "block"
    this.listTarget.style.display = "none"

    try {
      const response = await fetch(this.urlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
          "Accept": "application/json"
        }
      })

      const data = await response.json()

      if (data.success && data.action_plans) {
        this.displaySuggestions(data.action_plans)
      } else {
        this.displayError(data.error || "提案の取得に失敗しました")
      }
    } catch (error) {
      console.error("AI suggestions error:", error)
      this.displayError("提案の取得に失敗しました")
    }
  }

  displaySuggestions(actionPlans) {
    this.loadingTarget.style.display = "none"
    this.listTarget.style.display = "block"

    const html = `
      <div style="background: #f9fafb; border-radius: 12px; padding: 12px;">
        <div style="display: flex; align-items: center; gap: 6px; margin-bottom: 12px;">
          <svg style="width: 16px; height: 16px; color: #6b7280;" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
            <path stroke-linecap="round" stroke-linejoin="round" d="M9.813 15.904L9 18.75l-.813-2.846a4.5 4.5 0 00-3.09-3.09L2.25 12l2.846-.813a4.5 4.5 0 003.09-3.09L9 5.25l.813 2.846a4.5 4.5 0 003.09 3.09L15.75 12l-2.846.813a4.5 4.5 0 00-3.09 3.09z"/>
          </svg>
          <span style="font-size: 13px; font-weight: 600; color: #374151;">AIからの提案</span>
        </div>
        <div style="display: flex; flex-direction: column; gap: 8px;">
          ${actionPlans.map(plan => `
            <button type="button"
                    class="ai-suggestion-item"
                    data-action="click->ai-suggestions#selectPlan"
                    data-plan="${this.escapeHtml(plan)}"
                    style="text-align: left; padding: 10px 12px; background: white; border: 1px solid #e5e7eb; border-radius: 10px; cursor: pointer; font-size: 14px; color: #374151; transition: all 0.15s; display: flex; align-items: center; gap: 8px;">
              <span style="width: 18px; height: 18px; border: 2px solid #d1d5db; border-radius: 50%; flex-shrink: 0;"></span>
              <span>${this.escapeHtml(plan)}</span>
            </button>
          `).join('')}
        </div>
      </div>
    `

    this.listTarget.innerHTML = html

    // ホバーエフェクトを追加
    this.listTarget.querySelectorAll('.ai-suggestion-item').forEach(item => {
      item.addEventListener('mouseenter', () => {
        item.style.borderColor = '#6b7280'
        item.style.background = '#f9fafb'
      })
      item.addEventListener('mouseleave', () => {
        item.style.borderColor = '#e5e7eb'
        item.style.background = 'white'
      })
    })
  }

  selectPlan(event) {
    const plan = event.currentTarget.dataset.plan
    const textarea = document.querySelector('textarea[name="post_entry[content]"]')

    if (textarea) {
      textarea.value = plan
      textarea.focus()
      // 自動拡張を発火
      textarea.style.height = 'auto'
      textarea.style.height = textarea.scrollHeight + 'px'
    }

    // すべてのアイテムをリセット
    this.listTarget.querySelectorAll('.ai-suggestion-item').forEach(item => {
      item.style.borderColor = '#e5e7eb'
      item.style.background = 'white'
      const circle = item.querySelector('span:first-child')
      if (circle) {
        circle.style.borderColor = '#d1d5db'
        circle.style.background = 'transparent'
      }
    })

    // 選択したアイテムをハイライト（モノトーン）
    event.currentTarget.style.borderColor = '#374151'
    event.currentTarget.style.background = '#f9fafb'
    const selectedCircle = event.currentTarget.querySelector('span:first-child')
    if (selectedCircle) {
      selectedCircle.style.borderColor = '#374151'
      selectedCircle.style.background = '#374151'
    }
  }

  displayError(message) {
    this.loadingTarget.style.display = "none"
    this.listTarget.style.display = "block"

    this.listTarget.innerHTML = `
      <div style="padding: 12px; background: #fef2f2; border-radius: 12px; text-align: center;">
        <p style="font-size: 13px; color: #dc2626;">${this.escapeHtml(message)}</p>
        <button type="button"
                data-action="click->ai-suggestions#retry"
                style="margin-top: 8px; padding: 6px 12px; font-size: 12px; color: #6b7280; background: white; border: 1px solid #d1d5db; border-radius: 6px; cursor: pointer;">
          再試行
        </button>
      </div>
    `
  }

  retry() {
    this.fetch()
  }

  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }
}
