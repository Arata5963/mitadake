# frozen_string_literal: true

# app/services/youtube_service.rb
# YouTube Data API v3を使用して動画情報を取得するサービスクラス
#
# 主な機能:
# - 動画タイトルで検索（search_videos）
# - 動画URL/IDから詳細情報を取得（fetch_video_info）
# - チャンネルサムネイル取得
#
# 依存:
# - Google::Apis::YoutubeV3（gem 'google-api-client'）
# - Rails.application.config.youtube_service（初期化済みAPIクライアント）
#
# 環境変数:
# - YOUTUBE_API_KEY: YouTube Data API v3のAPIキー
class YoutubeService
  class << self
    # 動画をタイトルで検索
    # @param query [String] 検索クエリ
    # @param max_results [Integer] 最大結果数（デフォルト: 10）
    # @return [Array<Hash>] [{ video_id:, title:, channel_name:, thumbnail_url: }, ...]
    def search_videos(query, max_results: 10)
      return [] if query.blank?

      youtube = Rails.application.config.youtube_service
      return [] if youtube.nil?

      response = youtube.list_searches(
        "snippet",
        q: query,
        type: "video",
        max_results: max_results,
        order: "relevance"
      )

      response.items
        .select { |item| item.id.video_id.present? }  # チャンネル等を除外
        .map do |item|
          {
            video_id: item.id.video_id,
            title: item.snippet.title,
            channel_name: item.snippet.channel_title,
            thumbnail_url: item.snippet.thumbnails.medium&.url || item.snippet.thumbnails.default&.url,
            youtube_url: "https://www.youtube.com/watch?v=#{item.id.video_id}"
          }
        end
    rescue Google::Apis::ClientError => e
      Rails.logger.warn("YouTube API search error: #{e.message}")
      []
    rescue Google::Apis::ServerError => e
      Rails.logger.error("YouTube API server error: #{e.message}")
      []
    rescue Google::Apis::AuthorizationError => e
      Rails.logger.error("YouTube API authorization error: #{e.message}")
      []
    end

    # YouTube URLから動画情報（タイトル・チャンネル名）を取得
    # @param youtube_url [String] YouTube動画のURL
    # @return [Hash, nil] { title:, channel_name: } または nil（取得失敗時）
    def fetch_video_info(youtube_url)
      video_id = extract_video_id(youtube_url)
      return nil if video_id.blank?

      fetch_from_api(video_id)
    rescue Google::Apis::ClientError => e
      Rails.logger.warn("YouTube API client error: #{e.message}")
      nil
    rescue Google::Apis::ServerError => e
      Rails.logger.error("YouTube API server error: #{e.message}")
      nil
    rescue Google::Apis::AuthorizationError => e
      Rails.logger.error("YouTube API authorization error: #{e.message}")
      nil
    end

    private

    # YouTube URLからvideo_idを抽出
    # @param url [String] YouTube URL
    # @return [String, nil] video_id または nil
    def extract_video_id(url)
      return nil if url.blank?

      if url.include?("youtube.com/watch")
        URI.parse(url).query&.split("&")
           &.find { |p| p.start_with?("v=") }
           &.delete_prefix("v=")
      elsif url.include?("youtu.be/")
        url.split("youtu.be/").last&.split("?")&.first
      end
    rescue URI::InvalidURIError
      nil
    end

    # YouTube Data API v3から動画情報を取得
    # @param video_id [String] YouTube動画ID
    # @return [Hash, nil] { title:, channel_name:, channel_id:, channel_thumbnail_url: } または nil
    def fetch_from_api(video_id)
      youtube = Rails.application.config.youtube_service
      return nil if youtube.nil?

      response = youtube.list_videos("snippet", id: video_id)
      return nil if response.items.blank?

      video = response.items.first
      channel_id = video.snippet.channel_id
      channel_thumbnail_url = fetch_channel_thumbnail(youtube, channel_id)

      {
        title: video.snippet.title,
        channel_name: video.snippet.channel_title,
        channel_id: channel_id,
        channel_thumbnail_url: channel_thumbnail_url
      }
    end

    # チャンネルのサムネイル画像URLを取得
    # @param youtube [Google::Apis::YoutubeV3::YouTubeService] YouTubeサービスインスタンス
    # @param channel_id [String] チャンネルID
    # @return [String, nil] サムネイルURL または nil
    def fetch_channel_thumbnail(youtube, channel_id)
      return nil if channel_id.blank?

      response = youtube.list_channels("snippet", id: channel_id)
      return nil if response.items.blank?

      channel = response.items.first
      channel.snippet.thumbnails.default&.url ||
        channel.snippet.thumbnails.medium&.url
    rescue StandardError => e
      Rails.logger.warn("Failed to fetch channel thumbnail: #{e.message}")
      nil
    end
  end
end
