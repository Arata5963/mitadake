// app/javascript/utils/index.js
// ==========================================
// 共通ユーティリティ関数のエクスポート集約
// ==========================================
//
// 【このファイルの役割】
// utils/ フォルダ内の関数を1つにまとめてエクスポート。
// 他のファイルからはこのファイルをインポートするだけで
// 全てのユーティリティ関数にアクセスできる。
//
// 【使用例】
//   import { extractVideoId, escapeHtml, uploadToS3 } from "utils"
//
//   // または個別にインポート
//   import { extractVideoId } from "utils/youtube_helpers"
//
// 【含まれるモジュール】
//
// 1. youtube_helpers（YouTube関連）
//    - extractVideoId: URLから動画IDを抽出
//    - getThumbnailUrl: サムネイルURLを生成
//    - isYoutubeUrl: YouTube URLかどうか判定
//
// 2. html_helpers（HTML関連）
//    - escapeHtml: XSS対策のHTMLエスケープ
//    - getCsrfToken: CSRF保護トークン取得
//    - fetchJson: JSON APIリクエスト送信
//
// 3. s3_uploader（S3アップロード関連）
//    - uploadToS3: 署名付きURLでS3に直接アップロード
//    - isValidFileSize: ファイルサイズチェック
//    - isImageFile: 画像ファイルかどうか判定
//

// YouTube関連ヘルパー
export { extractVideoId, getThumbnailUrl, isYoutubeUrl } from "utils/youtube_helpers"

// HTML関連ヘルパー
export { escapeHtml, getCsrfToken, fetchJson } from "utils/html_helpers"

// S3アップローダー
export { uploadToS3, isValidFileSize, isImageFile } from "utils/s3_uploader"
