# frozen_string_literal: true

# YouTube Data API v3を使用して動画情報を取得するサービスクラス
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

    # 動画のトップコメントを取得（いいね数順）
    # @param video_id [String] YouTube動画ID
    # @param max_results [Integer] 取得数（デフォルト: 20）
    # @return [Array<Hash>] コメント配列
    def fetch_top_comments(video_id, max_results: 20)
      return [] if video_id.blank?

      youtube = Rails.application.config.youtube_service
      return [] if youtube.nil?

      # コメントを取得（relevanceで人気順に近い順序で取得）
      # APIの制限で直接いいね順には取得できないため、多めに取得してソート
      response = youtube.list_comment_threads(
        "snippet",
        video_id: video_id,
        max_results: 100, # 多めに取得
        order: "relevance",
        text_format: "plainText"
      )

      return [] if response.items.blank?

      # いいね数でソートしてトップN件を返す
      comments = response.items.map do |item|
        comment = item.snippet.top_level_comment
        snippet = comment.snippet
        {
          comment_id: comment.id,  # YouTube直リンク用
          author: snippet.author_display_name,
          author_image: snippet.author_profile_image_url,
          author_channel_url: snippet.author_channel_url,
          text: snippet.text_display,
          like_count: snippet.like_count || 0,
          published_at: snippet.published_at,
          updated_at: snippet.updated_at
        }
      end

      comments.sort_by { |c| -c[:like_count] }.first(max_results)
    rescue Google::Apis::ClientError => e
      # コメントが無効な動画の場合など
      Rails.logger.warn("YouTube API comments error: #{e.message}")
      []
    rescue Google::Apis::ServerError, Google::Apis::AuthorizationError => e
      Rails.logger.error("YouTube API error: #{e.message}")
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
