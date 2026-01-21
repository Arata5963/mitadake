// app/javascript/utils/youtube_helpers.js
// ==========================================
// YouTube関連のユーティリティ関数
// ==========================================
//
// 【このファイルの役割】
// YouTube URLの解析、動画IDの抽出、サムネイル取得など
// YouTube関連の共通処理をまとめたヘルパー関数群。
//
// 【主な機能】
// 1. extractVideoId: 各種形式のYouTube URLから動画IDを抽出
// 2. getThumbnailUrl: 動画IDからサムネイル画像URLを生成
// 3. isYoutubeUrl: 入力値がYouTube URLかどうか判定
//

// ------------------------------------------
// YouTube URLから動画IDを抽出
// ------------------------------------------
// 【何をする関数？】
// 各種形式のYouTube URLから11文字の動画IDを取り出す。
// 対応形式:
// - https://www.youtube.com/watch?v=dQw4w9WgXcQ
// - https://youtu.be/dQw4w9WgXcQ
// - https://youtube.com/embed/dQw4w9WgXcQ
// - dQw4w9WgXcQ（IDそのまま）
//
// 【引数】
// @param {string} url - YouTube URL または動画ID
//
// 【戻り値】
// @returns {string|null} 動画ID（11文字）またはnull（抽出失敗時）
//
// 【使用例】
//   extractVideoId("https://www.youtube.com/watch?v=dQw4w9WgXcQ")
//   // => "dQw4w9WgXcQ"
//
//   extractVideoId("https://youtu.be/dQw4w9WgXcQ")
//   // => "dQw4w9WgXcQ"
//
//   extractVideoId("dQw4w9WgXcQ")
//   // => "dQw4w9WgXcQ"
//
//   extractVideoId("invalid-url")
//   // => null
//
export function extractVideoId(url) {
  // 空の入力をチェック
  if (!url) return null

  // 正規表現パターン（複数形式に対応）
  const patterns = [
    // 通常のURL形式（youtube.com/watch?v=, youtu.be/, embed/）
    /(?:youtube\.com\/watch\?v=|youtu\.be\/|youtube\.com\/embed\/)([a-zA-Z0-9_-]{11})/,
    // IDのみ（11文字の英数字・ハイフン・アンダースコア）
    /^([a-zA-Z0-9_-]{11})$/
  ]

  // 各パターンでマッチを試行
  for (const pattern of patterns) {
    const match = url.match(pattern)
    if (match) return match[1]  // match[1] = キャプチャグループ（動画ID部分）
  }

  // どのパターンにもマッチしなかった
  return null
}

// ------------------------------------------
// 動画IDからサムネイルURLを生成
// ------------------------------------------
// 【何をする関数？】
// YouTube動画IDから、YouTubeが提供するサムネイル画像のURLを生成。
//
// 【サムネイルサイズの種類】
//   サイズ名       | 解像度      | 用途
//   ─────────────────────────────────────────
//   default        | 120x90     | 小さいリスト表示
//   mqdefault      | 320x180    | 中サイズ（デフォルト）
//   hqdefault      | 480x360    | 高品質
//   sddefault      | 640x480    | SD画質
//   maxresdefault  | 1280x720   | 最高画質（動画によっては存在しない）
//
// 【引数】
// @param {string} videoId - YouTube動画ID（11文字）
// @param {string} size - サムネイルサイズ（デフォルト: 'mqdefault'）
//
// 【戻り値】
// @returns {string} サムネイル画像のURL
//
// 【使用例】
//   getThumbnailUrl("dQw4w9WgXcQ")
//   // => "https://img.youtube.com/vi/dQw4w9WgXcQ/mqdefault.jpg"
//
//   getThumbnailUrl("dQw4w9WgXcQ", "hqdefault")
//   // => "https://img.youtube.com/vi/dQw4w9WgXcQ/hqdefault.jpg"
//
export function getThumbnailUrl(videoId, size = 'mqdefault') {
  return `https://img.youtube.com/vi/${videoId}/${size}.jpg`
}

// ------------------------------------------
// YouTube URLかどうかを判定
// ------------------------------------------
// 【何をする関数？】
// 入力値がYouTube URLまたは動画IDとして有効かどうかを判定。
// フォームのバリデーションや条件分岐に使用。
//
// 【引数】
// @param {string} value - 判定する文字列
//
// 【戻り値】
// @returns {boolean} YouTube URLなら true、そうでなければ false
//
// 【使用例】
//   isYoutubeUrl("https://youtu.be/dQw4w9WgXcQ")
//   // => true
//
//   isYoutubeUrl("hello world")
//   // => false
//
export function isYoutubeUrl(value) {
  return extractVideoId(value) !== null
}
