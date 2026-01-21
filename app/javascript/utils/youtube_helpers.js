// app/javascript/utils/youtube_helpers.js
// YouTube関連のユーティリティ関数

/**
 * YouTube URLから動画IDを抽出
 * @param {string} url - YouTube URL または動画ID
 * @returns {string|null} 動画ID（11文字）またはnull
 * @example
 *   extractVideoId("https://www.youtube.com/watch?v=dQw4w9WgXcQ") // => "dQw4w9WgXcQ"
 *   extractVideoId("https://youtu.be/dQw4w9WgXcQ") // => "dQw4w9WgXcQ"
 *   extractVideoId("dQw4w9WgXcQ") // => "dQw4w9WgXcQ"
 */
export function extractVideoId(url) {
  if (!url) return null

  const patterns = [
    /(?:youtube\.com\/watch\?v=|youtu\.be\/|youtube\.com\/embed\/)([a-zA-Z0-9_-]{11})/,
    /^([a-zA-Z0-9_-]{11})$/
  ]

  for (const pattern of patterns) {
    const match = url.match(pattern)
    if (match) return match[1]
  }
  return null
}

/**
 * 動画IDからサムネイルURLを生成
 * @param {string} videoId - YouTube動画ID
 * @param {string} size - サムネイルサイズ（default, mqdefault, hqdefault, sddefault, maxresdefault）
 * @returns {string} サムネイルURL
 */
export function getThumbnailUrl(videoId, size = 'mqdefault') {
  return `https://img.youtube.com/vi/${videoId}/${size}.jpg`
}

/**
 * YouTube URLかどうかを判定
 * @param {string} value - 入力値
 * @returns {boolean}
 */
export function isYoutubeUrl(value) {
  return extractVideoId(value) !== null
}
