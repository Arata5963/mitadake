# frozen_string_literal: true

# YouTube API連携サービス
# YouTube Data API v3を使って動画情報を取得

class YoutubeService
  class << self
    # 動画をタイトルで検索
    def search_videos(query, max_results: 10)
      return [] if query.blank?

      youtube = Rails.application.config.youtube_service      # config/initializers/youtube.rbで初期化
      return [] if youtube.nil?

      response = youtube.list_searches(
        "snippet",                                             # 基本情報（タイトル、説明など）を取得
        q: query,                                              # 検索キーワード
        type: "video",                                         # 動画のみ（チャンネル等を除外）
        max_results: max_results,
        order: "relevance"                                     # 関連度順
      )

      response.items
        .select { |item| item.id.video_id.present? }          # 動画IDがあるものだけ抽出
        .map do |item|
          {
            video_id: item.id.video_id,
            title: item.snippet.title,
            channel_name: item.snippet.channel_title,
            thumbnail_url: item.snippet.thumbnails.medium&.url || item.snippet.thumbnails.default&.url,
            youtube_url: "https://www.youtube.com/watch?v=#{item.id.video_id}"
          }
        end

    rescue Google::Apis::ClientError => e                     # 不正なリクエスト、クォータ超過など
      Rails.logger.warn("YouTube API search error: #{e.message}")
      []
    rescue Google::Apis::ServerError => e                     # YouTube側の問題
      Rails.logger.error("YouTube API server error: #{e.message}")
      []
    rescue Google::Apis::AuthorizationError => e              # APIキーが無効
      Rails.logger.error("YouTube API authorization error: #{e.message}")
      []
    end

    # YouTube URLから動画情報を取得
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

    # URLから動画IDを抽出
    def extract_video_id(url)
      return nil if url.blank?

      if url.include?("youtube.com/watch")                    # 通常形式
        URI.parse(url).query&.split("&")
           &.find { |p| p.start_with?("v=") }
           &.delete_prefix("v=")
      elsif url.include?("youtu.be/")                         # 短縮形式
        url.split("youtu.be/").last&.split("?")&.first
      end
    rescue URI::InvalidURIError
      nil
    end

    # YouTube Data APIから動画情報を取得
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
    def fetch_channel_thumbnail(youtube, channel_id)
      return nil if channel_id.blank?

      response = youtube.list_channels("snippet", id: channel_id)
      return nil if response.items.blank?

      channel = response.items.first
      channel.snippet.thumbnails.default&.url || channel.snippet.thumbnails.medium&.url

    rescue StandardError => e                                 # チャンネル情報取得失敗は無視
      Rails.logger.warn("Failed to fetch channel thumbnail: #{e.message}")
      nil
    end
  end
end
