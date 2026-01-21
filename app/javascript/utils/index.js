// app/javascript/utils/index.js
// 共通ユーティリティ関数のエクスポート集約ファイル
//
// このファイルをインポートすることで、全ユーティリティ関数にアクセス可能
// 使用例:
//   import { extractVideoId, escapeHtml, uploadToS3 } from "utils"
//
// 含まれるモジュール:
// - youtube_helpers: YouTube URL/動画ID関連
// - html_helpers: HTMLエスケープ、CSRF、fetchラッパー
// - s3_uploader: S3署名付きアップロード

export { extractVideoId, getThumbnailUrl, isYoutubeUrl } from "utils/youtube_helpers"
export { escapeHtml, getCsrfToken, fetchJson } from "utils/html_helpers"
export { uploadToS3, isValidFileSize, isImageFile } from "utils/s3_uploader"
