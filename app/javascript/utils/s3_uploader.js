// app/javascript/utils/s3_uploader.js
// S3アップロード関連のユーティリティ

import { getCsrfToken } from './html_helpers'

/**
 * ファイルをS3に直接アップロード（署名付きURL方式）
 * @param {File} file - アップロードするファイル
 * @param {Object} options - オプション
 * @param {string} options.presignUrl - 署名付きURL取得エンドポイント（デフォルト: /api/presigned_urls）
 * @returns {Promise<string>} S3キー
 * @throws {Error} アップロード失敗時
 */
export async function uploadToS3(file, options = {}) {
  const presignUrl = options.presignUrl || '/api/presigned_urls'

  // 1. 署名付きURLを取得
  const presignResponse = await fetch(presignUrl, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': getCsrfToken()
    },
    body: JSON.stringify({
      filename: file.name,
      content_type: file.type
    })
  })

  if (!presignResponse.ok) {
    throw new Error('署名付きURLの取得に失敗しました')
  }

  const { upload_url, s3_key } = await presignResponse.json()

  // 2. S3に直接PUT
  const uploadResponse = await fetch(upload_url, {
    method: 'PUT',
    headers: {
      'Content-Type': file.type
    },
    body: file
  })

  if (!uploadResponse.ok) {
    throw new Error('S3へのアップロードに失敗しました')
  }

  return s3_key
}

/**
 * ファイルサイズをチェック
 * @param {File} file - チェックするファイル
 * @param {number} maxSizeMB - 最大サイズ（MB）
 * @returns {boolean} サイズが有効かどうか
 */
export function isValidFileSize(file, maxSizeMB = 5) {
  return file.size <= maxSizeMB * 1024 * 1024
}

/**
 * 画像ファイルかどうかをチェック
 * @param {File} file - チェックするファイル
 * @returns {boolean}
 */
export function isImageFile(file) {
  return file.type.startsWith('image/')
}
