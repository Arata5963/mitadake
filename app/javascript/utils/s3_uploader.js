// app/javascript/utils/s3_uploader.js
// ==========================================
// S3アップロード関連のユーティリティ
// ==========================================
//
// 【このファイルの役割】
// AWS S3への画像アップロードを「署名付きURL方式」で行う。
// サーバーを経由せずにブラウザから直接S3にアップロードする。
//
// 【署名付きURL（Presigned URL）方式とは？】
//
//   【従来の方式（サーバー経由）】
//   ブラウザ → Railsサーバー → S3
//   問題: サーバーのメモリ・帯域を消費、遅い
//
//   【署名付きURL方式】
//   1. ブラウザ → Railsサーバー（URLだけ取得）
//   2. ブラウザ → S3（直接アップロード）
//   メリット: サーバー負荷軽減、高速
//
// 【処理フロー】
//   1. Railsに署名付きURLを要求
//   2. Railsが一時的なアップロードURLを発行
//   3. ブラウザがそのURLに直接ファイルをPUT
//   4. S3に保存される
//   5. s3_key をRailsに送って保存
//

import { getCsrfToken } from "utils/html_helpers"

// ------------------------------------------
// ファイルをS3に直接アップロード
// ------------------------------------------
// 【何をする関数？】
// 画像ファイルをS3に直接アップロードし、S3キーを返す。
// 内部で署名付きURL取得 → S3アップロードの2段階処理を行う。
//
// 【引数】
// @param {File} file - アップロードするファイル（<input type="file">から取得）
// @param {Object} options - オプション
// @param {string} options.presignUrl - 署名付きURL取得エンドポイント
//                                      デフォルト: '/api/presigned_urls'
//
// 【戻り値】
// @returns {Promise<string>} S3キー（例: "user_thumbnails/123/uuid.jpg"）
//
// 【例外】
// @throws {Error} URLの取得やアップロードに失敗した場合
//
// 【使用例】
//   const file = event.target.files[0]  // ファイル選択から取得
//   try {
//     const s3Key = await uploadToS3(file)
//     console.log("アップロード成功:", s3Key)
//     // s3Keyをサーバーに送信して保存
//   } catch (error) {
//     console.error("アップロード失敗:", error.message)
//   }
//
export async function uploadToS3(file, options = {}) {
  const presignUrl = options.presignUrl || '/api/presigned_urls'

  // ------------------------------------------
  // ステップ1: 署名付きURLを取得
  // ------------------------------------------
  // Railsサーバーに「アップロード用の一時URLをください」とリクエスト
  //
  const presignResponse = await fetch(presignUrl, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': getCsrfToken()  // CSRF保護
    },
    body: JSON.stringify({
      filename: file.name,            // ファイル名（ログ用）
      content_type: file.type         // MIMEタイプ（image/jpeg など）
    })
  })

  // エラーチェック
  if (!presignResponse.ok) {
    throw new Error('署名付きURLの取得に失敗しました')
  }

  // レスポンスからURL取得
  // { upload_url: "https://s3...", s3_key: "user_thumbnails/..." }
  const { upload_url, s3_key } = await presignResponse.json()

  // ------------------------------------------
  // ステップ2: S3に直接PUT
  // ------------------------------------------
  // 署名付きURLに対してファイルを直接アップロード
  // このリクエストはRailsサーバーを経由しない
  //
  const uploadResponse = await fetch(upload_url, {
    method: 'PUT',
    headers: {
      'Content-Type': file.type       // ファイルのMIMEタイプ
    },
    body: file                        // ファイル本体
  })

  // エラーチェック
  if (!uploadResponse.ok) {
    throw new Error('S3へのアップロードに失敗しました')
  }

  // S3キーを返す（後でRailsに保存）
  return s3_key
}

// ------------------------------------------
// ファイルサイズをチェック
// ------------------------------------------
// 【何をする関数？】
// アップロード前にファイルサイズが上限以下かチェック。
// ユーザー体験とサーバー負荷軽減のため。
//
// 【引数】
// @param {File} file - チェックするファイル
// @param {number} maxSizeMB - 最大サイズ（MB単位、デフォルト: 5）
//
// 【戻り値】
// @returns {boolean} サイズが有効なら true、超過なら false
//
// 【使用例】
//   if (!isValidFileSize(file, 5)) {
//     alert('ファイルサイズは5MB以下にしてください')
//     return
//   }
//
export function isValidFileSize(file, maxSizeMB = 5) {
  // 1MB = 1024 * 1024 bytes
  return file.size <= maxSizeMB * 1024 * 1024
}

// ------------------------------------------
// 画像ファイルかどうかをチェック
// ------------------------------------------
// 【何をする関数？】
// ファイルが画像形式かどうかをMIMEタイプで判定。
// 画像以外のファイルをはじくために使用。
//
// 【MIMEタイプとは？】
// ファイルの種類を表す文字列。例:
// - image/jpeg → JPG画像
// - image/png → PNG画像
// - text/html → HTMLファイル
//
// 【引数】
// @param {File} file - チェックするファイル
//
// 【戻り値】
// @returns {boolean} 画像ファイルなら true
//
// 【使用例】
//   if (!isImageFile(file)) {
//     alert('画像ファイルを選択してください')
//     return
//   }
//
export function isImageFile(file) {
  // startsWith: 文字列が指定の接頭辞で始まるかチェック
  // image/jpeg, image/png, image/webp など全て image/ で始まる
  return file.type.startsWith('image/')
}
