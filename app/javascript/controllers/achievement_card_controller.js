// 達成カードコントローラー
// カードクリック時に達成記録モーダルを開く（input: 入力用 / display: 閲覧用）

import { Controller } from "@hotwired/stimulus"  // Stimulusコントローラー基底クラス

export default class extends Controller {
  static values = {
    entryId: Number,                                 // エントリーID
    postId: Number,                                  // 投稿ID
    showUrl: String,                                 // 詳細取得URL
    achieveUrl: String,                              // 達成記録URL
    editUrl: String,                                 // 編集URL
    deleteUrl: String,                               // 削除URL
    mode: { type: String, default: "display" },      // モード（input/display）
    hideOriginalVideo: { type: Boolean, default: false },  // 動画リンク非表示フラグ
    videoThumbnail: String,                          // サムネイルURL
    videoUrl: String,                                // 動画URL
    videoTitle: String                               // 動画タイトル
  }

  // カードクリック時にモーダルを開く
  async open(event) {
    event.preventDefault()                           // デフォルト動作を防止
    event.stopPropagation()                          // イベント伝播を停止

    if (this.modeValue === "input") {                // 入力モードの場合
      this.renderInputModal()                        // 入力モーダルを表示
      return                                         // 処理終了
    }

    try {
      const response = await fetch(this.showUrlValue, { headers: { "Accept": "application/json" } })  // APIからデータ取得
      const data = await response.json()             // JSONをパース
      this.renderDisplayModal(data)                  // 閲覧モーダルを表示
    } catch (error) {
      console.error("Failed to load achievement:", error)  // エラーログ出力
    }
  }

  // 入力モード用モーダルを表示
  renderInputModal() {
    const container = document.getElementById("achievement_modal")  // モーダルコンテナを取得
    if (!container) return                           // コンテナがなければ終了
    container.innerHTML = this.buildInputModalHtml() // HTMLを挿入
  }

  // 閲覧モード用モーダルを表示
  renderDisplayModal(data) {
    const container = document.getElementById("achievement_modal")  // モーダルコンテナを取得
    if (!container) return                           // コンテナがなければ終了
    container.innerHTML = this.buildDisplayModalHtml(data)  // HTMLを挿入
  }

  // 入力モード用HTMLを生成
  buildInputModalHtml() {
    return `
      <div data-controller="achievement-modal"
           data-achievement-modal-entry-id-value="${this.entryIdValue}"
           data-achievement-modal-post-id-value="${this.postIdValue}"
           data-achievement-modal-mode-value="input"
           data-achievement-modal-achieve-url-value="${this.achieveUrlValue}"
           data-achievement-modal-delete-url-value="${this.deleteUrlValue || ''}"
           data-achievement-modal-edit-url-value="${this.editUrlValue || ''}">

        <div class="fixed inset-0 z-50 flex items-center justify-center p-4"
             data-action="click->achievement-modal#closeOnOverlay">

          <div class="absolute inset-0 bg-black/60 backdrop-blur-sm pointer-events-none"></div>

          <div class="relative bg-white rounded-2xl max-w-md w-full max-h-[90vh] overflow-y-auto shadow-xl">

            <div class="flex items-center justify-between p-4 border-b border-gray-100">
              <h2 class="text-base font-bold text-gray-900">達成を記録</h2>
              <div class="flex items-center gap-1">
                <button type="button"
                   class="flex items-center gap-1 px-2 py-1 hover:bg-gray-100 rounded text-xs text-gray-500 transition-colors"
                   title="編集"
                   data-edit-url="${this.editUrlValue}"
                   data-action="click->achievement-modal#goToEdit">
                  <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z"/>
                  </svg>
                </button>
                <a href="${this.videoUrlValue}"
                   class="flex items-center gap-1 px-2 py-1 hover:bg-gray-100 rounded text-xs text-gray-500 transition-colors"
                   title="きっかけの動画">
                  <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M14.752 11.168l-3.197-2.132A1 1 0 0010 9.87v4.263a1 1 0 001.555.832l3.197-2.132a1 1 0 000-1.664z"/>
                    <path stroke-linecap="round" stroke-linejoin="round" d="M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
                  </svg>
                </a>
              </div>
            </div>

            <div class="p-4">
              <label class="block text-sm font-medium text-gray-700 mb-2">達成の記念写真<span class="text-red-500 ml-1">*</span></label>

              <div style="position: relative;">
                <label style="position: relative; display: block; border-radius: 8px; overflow: hidden; background: #f3f4f6; aspect-ratio: 16/9; cursor: pointer;">
                  <div data-achievement-modal-target="uploadArea"
                       data-action="click->achievement-modal#triggerFileInput"
                       style="position: absolute; inset: 0; display: flex; flex-direction: column; align-items: center; justify-content: center; border: 2px dashed #ccc; border-radius: 8px;">
                    <svg style="width: 32px; height: 32px; color: #999; margin-bottom: 8px;" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"/>
                    </svg>
                    <span style="font-size: 13px; font-weight: 500; color: #666;">クリックして画像を選択</span>
                    <span style="font-size: 11px; color: #999; margin-top: 4px;">JPG, PNG（最大10MB）</span>
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

  // 閲覧モード用HTMLを生成
  buildDisplayModalHtml(data) {
    const thumbnailUrl = data.result_image_url || data.fallback_thumbnail_url  // サムネイルURL（結果画像優先）
    const canEdit = data.can_edit                    // 編集可能フラグ
    const editUrl = `/posts/${data.post.id}/post_entries/${data.id}/edit?from=mypage`  // 編集URL

    return `
      <div data-controller="achievement-modal"
           data-achievement-modal-entry-id-value="${data.id}"
           data-achievement-modal-post-id-value="${data.post.id}"
           data-achievement-modal-mode-value="display"
           data-achievement-modal-update-reflection-url-value="/posts/${data.post.id}/post_entries/${data.id}/update_reflection">

        <div class="fixed inset-0 z-50 flex items-center justify-center p-4"
             data-action="click->achievement-modal#closeOnOverlay">

          <div class="absolute inset-0 bg-black/60 backdrop-blur-sm pointer-events-none"></div>

          <div class="relative bg-white rounded-2xl max-w-md w-full max-h-[90vh] overflow-y-auto shadow-xl">

            <div class="absolute top-3 right-3 flex items-center gap-1 z-10">
              ${canEdit ? `
                <a href="${editUrl}"
                   class="w-8 h-8 flex items-center justify-center rounded-full bg-white/80 hover:bg-white text-gray-500 hover:text-gray-700"
                   title="編集">
                  <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z"/>
                  </svg>
                </a>
              ` : ''}
              ${!this.hideOriginalVideoValue ? `
                <a href="${data.post.url}"
                   class="w-8 h-8 flex items-center justify-center rounded-full bg-white/80 hover:bg-white text-gray-500 hover:text-gray-700"
                   title="きっかけの動画">
                  <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M14.752 11.168l-3.197-2.132A1 1 0 0010 9.87v4.263a1 1 0 001.555.832l3.197-2.132a1 1 0 000-1.664z"/>
                    <path stroke-linecap="round" stroke-linejoin="round" d="M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
                  </svg>
                </a>
              ` : ''}
            </div>

            <div class="aspect-video bg-gray-100 rounded-t-2xl overflow-hidden relative">
              <img src="${thumbnailUrl}"
                   alt=""
                   class="w-full h-full object-cover"
                   data-achievement-modal-target="displayImage">
              <!-- 編集用：新しい画像のプレビュー（初期非表示） -->
              <img src=""
                   alt="プレビュー"
                   class="w-full h-full object-cover absolute inset-0 hidden"
                   data-achievement-modal-target="editImagePreview">
            </div>
            <!-- 編集用：画像変更リンク（初期非表示） -->
            ${canEdit ? `
              <div class="hidden flex justify-end px-4 pt-1" data-achievement-modal-target="editImageSection">
                <button type="button"
                        class="text-xs text-gray-500 hover:text-gray-700"
                        data-action="click->achievement-modal#triggerEditFileInput">
                  画像を変更
                </button>
                <input type="file"
                       accept="image/jpeg,image/png,image/webp"
                       data-achievement-modal-target="editImageInput"
                       data-action="change->achievement-modal#handleEditFileSelect"
                       style="display: none;">
              </div>
            ` : ''}

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
                <p class="text-sm text-gray-600 whitespace-pre-wrap text-left" data-achievement-modal-target="reflectionDisplay">${this.escapeHtml(data.reflection)}</p>
                <textarea class="hidden w-full p-3 border border-gray-200 rounded-lg text-sm resize-none focus:outline-none focus:ring-2 focus:ring-gray-900 focus:border-transparent"
                          rows="3"
                          placeholder="達成した感想を入力..."
                          maxlength="500"
                          data-achievement-modal-target="reflectionInput"></textarea>
              </div>

            </div>
          </div>
        </div>
      </div>
    `
  }

  // HTMLエスケープ処理
  escapeHtml(text) {
    if (!text) return ''                             // 空なら空文字を返す
    const div = document.createElement("div")        // 一時的なdiv要素を作成
    div.textContent = text                           // テキストとして設定（自動エスケープ）
    return div.innerHTML                             // エスケープ済みHTMLを返す
  }
}
