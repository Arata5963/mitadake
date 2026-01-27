// S3アップロードユーティリティ
// 署名付きURL方式でブラウザからS3に直接アップロード

import { getCsrfToken } from "utils/html_helpers"

// ファイルをS3に直接アップロードしてS3キーを返す
export async function uploadToS3(file, options = {}) {
  const presignUrl = options.presignUrl || '/api/presigned_urls'

  // ステップ1: Railsから署名付きURLを取得
  const presignResponse = await fetch(presignUrl, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': getCsrfToken()
    },
    body: JSON.stringify({
      filename: file.name,     // ファイル名（ログ用）
      content_type: file.type  // MIMEタイプ
    })
  })

  if (!presignResponse.ok) {
    throw new Error('署名付きURLの取得に失敗しました')
  }

  const { upload_url, s3_key } = await presignResponse.json()

  // ステップ2: S3に直接PUT（Railsサーバーを経由しない）
  const uploadResponse = await fetch(upload_url, {
    method: 'PUT',
    headers: { 'Content-Type': file.type },
    body: file
  })

  if (!uploadResponse.ok) {
    throw new Error('S3へのアップロードに失敗しました')
  }

  return s3_key  // 後でRailsに保存
}

// ファイルサイズが上限以下かチェック
export function isValidFileSize(file, maxSizeMB = 5) {
  return file.size <= maxSizeMB * 1024 * 1024  // 1MB = 1024 * 1024 bytes
}

// 画像ファイルかどうかをMIMEタイプで判定
export function isImageFile(file) {
  return file.type.startsWith('image/')  // image/jpeg, image/png など
}
