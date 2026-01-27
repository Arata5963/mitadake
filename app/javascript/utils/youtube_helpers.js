// YouTube関連ユーティリティ関数
// URL解析、動画ID抽出、サムネイル取得などの共通処理

// YouTube URLから動画IDを抽出（各種形式に対応）
export function extractVideoId(url) {
  if (!url) return null  // 空入力チェック

  const patterns = [
    /(?:youtube\.com\/watch\?v=|youtu\.be\/|youtube\.com\/embed\/)([a-zA-Z0-9_-]{11})/,  // URL形式
    /^([a-zA-Z0-9_-]{11})$/                                                              // IDのみ
  ]

  for (const pattern of patterns) {
    const match = url.match(pattern)
    if (match) return match[1]  // 動画ID部分を返す
  }

  return null
}

// 動画IDからサムネイルURLを生成
export function getThumbnailUrl(videoId, size = 'mqdefault') {
  return `https://img.youtube.com/vi/${videoId}/${size}.jpg`
}

// YouTube URLかどうかを判定
export function isYoutubeUrl(value) {
  return extractVideoId(value) !== null
}
