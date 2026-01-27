# frozen_string_literal: true

# YouTube Data API v3 設定
# 動画情報取得・検索機能で使用するAPIクライアントを初期化

require "google/apis/youtube_v3"

# APIキーが設定されている場合のみクライアントを初期化
Rails.application.config.youtube_service = if ENV["YOUTUBE_API_KEY"].present?
  Google::Apis::YoutubeV3::YouTubeService.new.tap do |youtube|
    youtube.key = ENV["YOUTUBE_API_KEY"]  # APIキーを設定
  end
end
