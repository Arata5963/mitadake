// app/javascript/controllers/achievement_card_controller.js
// ==========================================
// 達成カードコントローラー
// ==========================================
//
// 【このコントローラーの役割】
// 達成済みアクションプランのカードをクリックした時に
// 達成記録モーダルを開く。
//
// 【2つのモード】
// 1. input モード: 達成ボタンをクリック → 感想・画像入力モーダル
// 2. display モード: 達成済みカードをクリック → 閲覧用モーダル
//
// 【achievement_modal_controller との関係】
// このコントローラーがモーダルのHTMLを生成して
// #achievement_modal 要素に挿入する。
// その後、achievement_modal_controller が動作を制御する。
//
// 【処理フロー】
//
//   1. カードがクリックされる（open メソッド）
//      ↓
//   2. モードを判定（input / display）
//      ↓
//   3. モードに応じたHTMLを生成
//      - buildInputModalHtml(): 入力用
//      - buildDisplayModalHtml(): 表示用
//      ↓
//   4. #achievement_modal に挿入
//      ↓
//   5. achievement_modal_controller が起動
//
// 【HTML側の使い方】
//   <div data-controller="achievement-card"
//        data-achievement-card-entry-id-value="123"
//        data-achievement-card-post-id-value="456"
//        data-achievement-card-mode-value="display"
//        data-achievement-card-show-url-value="/posts/456/entries/123/show_achievement"
//        data-action="click->achievement-card#open">
//     カードの内容
//   </div>
//

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    entryId: Number,
    postId: Number,
    showUrl: String,
    achieveUrl: String,
    mode: { type: String, default: "display" },
    hideOriginalVideo: { type: Boolean, default: false },
    videoThumbnail: String,
    videoUrl: String,
    videoTitle: String
  }

  async open(event) {
    event.preventDefault()
    event.stopPropagation()

    // 入力モード（達成時）
    if (this.modeValue === "input") {
      this.renderInputModal()
      return
    }

    // 表示モード（閲覧時）
    try {
      const response = await fetch(this.showUrlValue, {
        headers: { "Accept": "application/json" }
      })

      const data = await response.json()
      this.renderDisplayModal(data)
    } catch (error) {
      console.error("Failed to load achievement:", error)
    }
  }

  renderInputModal() {
    const container = document.getElementById("achievement_modal")
    if (!container) return

    const html = this.buildInputModalHtml()
    container.innerHTML = html
  }

  renderDisplayModal(data) {
    const container = document.getElementById("achievement_modal")
    if (!container) return

    const html = this.buildDisplayModalHtml(data)
    container.innerHTML = html
  }

  buildInputModalHtml() {
    return `
      <div data-controller="achievement-modal"
           data-achievement-modal-entry-id-value="${this.entryIdValue}"
           data-achievement-modal-post-id-value="${this.postIdValue}"
           data-achievement-modal-mode-value="input"
           data-achievement-modal-achieve-url-value="${this.achieveUrlValue}">

        <div class="fixed inset-0 z-50 flex items-center justify-center p-4"
             data-action="click->achievement-modal#closeOnOverlay">

          <div class="absolute inset-0 bg-black/60 backdrop-blur-sm"></div>

          <div class="relative bg-white rounded-2xl max-w-md w-full max-h-[90vh] overflow-y-auto shadow-xl">

            <button type="button"
                    class="absolute top-3 right-3 w-8 h-8 flex items-center justify-center rounded-full bg-white/80 hover:bg-white text-gray-500 hover:text-gray-700 z-10"
                    data-action="click->achievement-modal#close">
              <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12"/>
              </svg>
            </button>

            <div class="p-4 border-b border-gray-100">
              <h2 class="text-base font-bold text-gray-900 text-center">達成を記録</h2>
            </div>

            <div class="p-4">
              <label class="block text-sm font-medium text-gray-700 mb-2">達成の記念写真（任意）</label>

              <div style="position: relative;">
                <label style="position: relative; display: block; border-radius: 8px; overflow: hidden; background: #f3f4f6; aspect-ratio: 16/9; cursor: pointer;">
                  <div data-achievement-modal-target="uploadArea"
                       data-action="click->achievement-modal#triggerFileInput"
                       style="position: absolute; inset: 0; display: flex; flex-direction: column; align-items: center; justify-content: center; border: 2px dashed #ccc; border-radius: 8px;">
                    <svg style="width: 32px; height: 32px; color: #999; margin-bottom: 8px;" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"/>
                    </svg>
                    <span style="font-size: 13px; font-weight: 500; color: #666;">クリックして画像を選択</span>
                    <span style="font-size: 11px; color: #999; margin-top: 4px;">JPG, PNG（最大5MB）</span>
                  </div>
                  <img data-achievement-modal-target="imagePreview"
                       src=""
                       alt="プレビュー"
                       style="display: none; width: 100%; height: 100%; object-fit: cover;">
                  <input type="file"
                         accept="image/jpeg,image/png,image/webp"
                         data-achievement-modal-target="imageInput"
                         data-action="change->achievement-modal#handleFileSelect"
                         style="display: none;">
                </label>
                <button type="button"
                        data-achievement-modal-target="clearImageBtn"
                        data-action="click->achievement-modal#clearImage"
                        style="display: none; position: absolute; top: -8px; right: -8px; width: 24px; height: 24px; background: #333; color: #fff; border: none; border-radius: 50%; cursor: pointer; align-items: center; justify-content: center; font-size: 12px; z-index: 10;">
                  ✕
                </button>
              </div>
            </div>

            <div class="px-4 pb-4">
              <label class="block text-sm font-medium text-gray-700 mb-2">達成した感想<span class="text-red-500 ml-1">*</span></label>
              <textarea class="w-full p-2 border border-gray-200 rounded-lg text-sm resize-none focus:outline-none focus:ring-2 focus:ring-gray-900 focus:border-transparent"
                        rows="2"
                        placeholder="感想を残そう"
                        maxlength="500"
                        data-achievement-modal-target="reflectionInput"></textarea>
            </div>

            <div class="px-4 pb-4">
              <button type="button"
                      class="w-full py-2.5 bg-gray-900 hover:bg-gray-800 text-white text-sm font-medium rounded-lg transition-colors"
                      data-action="click->achievement-modal#submit"
                      data-achievement-modal-target="submitBtn">
                達成を記録する
              </button>
            </div>

            <div class="hidden absolute inset-0 bg-white/80 items-center justify-center rounded-2xl"
                 data-achievement-modal-target="loadingOverlay">
              <div class="flex flex-col items-center">
                <div class="w-8 h-8 border-3 border-gray-200 border-t-gray-900 rounded-full animate-spin"></div>
                <p class="text-sm text-gray-600 mt-3">記録中...</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    `
  }

  buildDisplayModalHtml(data) {
    const thumbnailUrl = data.result_image_url || data.fallback_thumbnail_url
    const canEdit = data.can_edit

    return `
      <div data-controller="achievement-modal"
           data-achievement-modal-entry-id-value="${data.id}"
           data-achievement-modal-post-id-value="${data.post.id}"
           data-achievement-modal-mode-value="display"
           data-achievement-modal-update-reflection-url-value="/posts/${data.post.id}/post_entries/${data.id}/update_reflection">

        <div class="fixed inset-0 z-50 flex items-center justify-center p-4"
             data-action="click->achievement-modal#closeOnOverlay">

          <div class="absolute inset-0 bg-black/60 backdrop-blur-sm"></div>

          <div class="relative bg-white rounded-2xl max-w-md w-full max-h-[90vh] overflow-y-auto shadow-xl">

            <button type="button"
                    class="absolute top-3 right-3 w-8 h-8 flex items-center justify-center rounded-full bg-white/80 hover:bg-white text-gray-500 hover:text-gray-700 z-10"
                    data-action="click->achievement-modal#close">
              <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12"/>
              </svg>
            </button>

            <div class="aspect-video bg-gray-100 rounded-t-2xl overflow-hidden">
              <img src="${thumbnailUrl}"
                   alt=""
                   class="w-full h-full object-cover">
            </div>

            <div class="p-4">
              <h3 class="text-lg font-bold text-gray-900 mb-4">
                ${this.escapeHtml(data.content)}
              </h3>

              <div class="mb-4">
                <div class="flex items-center justify-between mb-2">
                  <span class="text-sm font-medium text-gray-700">感想</span>
                  ${canEdit ? `
                    <button type="button"
                            class="text-xs text-gray-500 hover:text-gray-700"
                            data-action="click->achievement-modal#switchToEdit"
                            data-achievement-modal-target="editBtn">
                      編集
                    </button>
                  ` : ''}
                </div>
                <p class="text-sm text-gray-600 whitespace-pre-wrap" data-achievement-modal-target="reflectionDisplay">
                  ${this.escapeHtml(data.reflection)}
                </p>
                <textarea class="hidden w-full p-3 border border-gray-200 rounded-lg text-sm resize-none focus:outline-none focus:ring-2 focus:ring-gray-900 focus:border-transparent"
                          rows="3"
                          placeholder="達成した感想を入力..."
                          maxlength="500"
                          data-achievement-modal-target="reflectionInput"></textarea>
              </div>

              ${!this.hideOriginalVideoValue ? `
              <a href="${data.post.url}"
                 class="flex items-center justify-center w-full py-3 bg-gray-100 hover:bg-gray-200 rounded-lg text-sm font-medium text-gray-700 transition-colors">
                きっかけの動画
              </a>
              ` : ''}
            </div>
          </div>
        </div>
      </div>
    `
  }

  escapeHtml(text) {
    if (!text) return ''
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  }
}
