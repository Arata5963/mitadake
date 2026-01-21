# spec/services/youtube_service_spec.rb
# ==========================================
# YoutubeService のテスト
# ==========================================
#
# 【このファイルの役割】
# YouTube Data API v3 を使った動画情報取得と
# 検索機能のテスト。
#
# 【テストの実行方法】
#   docker compose exec web rspec spec/services/youtube_service_spec.rb
#
# 【テスト対象】
# - fetch_video_info: 動画情報の取得
# - search_videos: 動画検索
#
# 【モック化について】
# 実際のYouTube APIを呼ばずにテストするため、
# APIレスポンスをモック化している。
#
# 【instance_double】
# 特定のクラスのインスタンスをモック化。
# 実際のメソッドシグネチャと一致するか検証される。
#
#   youtube_service = instance_double(Google::Apis::YoutubeV3::YouTubeService)
#   allow(youtube_service).to receive(:list_videos).and_return(response)
#

require 'rails_helper'

RSpec.describe YoutubeService, type: :service, youtube_api: true do
  # ==========================================
  # 動画情報取得のテスト
  # ==========================================
  # 【何をテストしている？】
  # YouTube URLから動画のタイトル、チャンネル名、
  # サムネイルを取得する機能。
  #
  describe '.fetch_video_info' do
    let(:video_id) { 'dQw4w9WgXcQ' }
    let(:channel_id) { 'UCtest123' }
    let(:youtube_url) { "https://www.youtube.com/watch?v=#{video_id}" }

    before do
      # YouTube APIサービスをモック
      @youtube_service = instance_double(Google::Apis::YoutubeV3::YouTubeService)
      allow(Rails.application.config).to receive(:youtube_service).and_return(@youtube_service)

      # 動画APIレスポンスをモック
      video_snippet = double(
        title: 'Test Video Title',
        channel_title: 'Test Channel',
        channel_id: channel_id
      )
      video_item = double(snippet: video_snippet)
      video_response = double(items: [video_item])
      allow(@youtube_service).to receive(:list_videos).with('snippet', id: video_id).and_return(video_response)

      # チャンネルAPIレスポンスをモック
      channel_thumbnail = double(url: 'https://example.com/channel_thumbnail.jpg')
      channel_thumbnails = double(default: channel_thumbnail, medium: nil)
      channel_snippet = double(thumbnails: channel_thumbnails)
      channel_item = double(snippet: channel_snippet)
      channel_response = double(items: [channel_item])
      allow(@youtube_service).to receive(:list_channels).with('snippet', id: channel_id).and_return(channel_response)
    end

    # ------------------------------------------
    # 正常系テスト
    # ------------------------------------------
    context '有効なYouTube URLの場合' do
      it '動画情報を返す' do
        result = described_class.fetch_video_info(youtube_url)

        expect(result).to include(
          title: 'Test Video Title',
          channel_name: 'Test Channel',
          channel_id: channel_id
        )
      end
    end

    context 'youtu.be形式のURLの場合' do
      let(:short_url) { "https://youtu.be/#{video_id}" }

      it '動画情報を返す' do
        result = described_class.fetch_video_info(short_url)

        expect(result).to include(
          title: 'Test Video Title',
          channel_name: 'Test Channel'
        )
      end
    end

    context 'パラメータ付きyoutu.be形式のURLの場合' do
      let(:short_url_with_params) { "https://youtu.be/#{video_id}?t=10" }

      it '動画情報を返す' do
        result = described_class.fetch_video_info(short_url_with_params)

        expect(result).to include(
          title: 'Test Video Title',
          channel_name: 'Test Channel'
        )
      end
    end

    # ------------------------------------------
    # 異常系テスト
    # ------------------------------------------
    context 'URLがnilの場合' do
      it 'nilを返す' do
        result = described_class.fetch_video_info(nil)
        expect(result).to be_nil
      end
    end

    context 'URLが空の場合' do
      it 'nilを返す' do
        result = described_class.fetch_video_info('')
        expect(result).to be_nil
      end
    end

    context '無効なURLの場合' do
      it 'nilを返す' do
        result = described_class.fetch_video_info('https://example.com')
        expect(result).to be_nil
      end
    end

    context 'YouTube APIサービスが設定されていない場合' do
      before do
        allow(Rails.application.config).to receive(:youtube_service).and_return(nil)
      end

      it 'nilを返す' do
        result = described_class.fetch_video_info(youtube_url)
        expect(result).to be_nil
      end
    end

    context '動画が存在しない場合' do
      before do
        youtube_service = instance_double(Google::Apis::YoutubeV3::YouTubeService)
        allow(Rails.application.config).to receive(:youtube_service).and_return(youtube_service)
        response = double(items: [])
        allow(youtube_service).to receive(:list_videos).and_return(response)
      end

      it 'nilを返す' do
        result = described_class.fetch_video_info(youtube_url)
        expect(result).to be_nil
      end
    end

    # ------------------------------------------
    # APIエラーのテスト
    # ------------------------------------------
    context 'APIクライアントエラー(404, 403など)が発生した場合' do
      before do
        youtube_service = instance_double(Google::Apis::YoutubeV3::YouTubeService)
        allow(Rails.application.config).to receive(:youtube_service).and_return(youtube_service)
        allow(youtube_service).to receive(:list_videos).and_raise(Google::Apis::ClientError.new('Not Found'))
      end

      it 'nilを返す' do
        result = described_class.fetch_video_info(youtube_url)
        expect(result).to be_nil
      end

      it 'エラーをログに記録する' do
        expect(Rails.logger).to receive(:warn).with(/YouTube API client error/)
        described_class.fetch_video_info(youtube_url)
      end
    end

    context 'APIサーバーエラーが発生した場合' do
      before do
        youtube_service = instance_double(Google::Apis::YoutubeV3::YouTubeService)
        allow(Rails.application.config).to receive(:youtube_service).and_return(youtube_service)
        allow(youtube_service).to receive(:list_videos).and_raise(Google::Apis::ServerError.new('Internal Server Error'))
      end

      it 'nilを返す' do
        result = described_class.fetch_video_info(youtube_url)
        expect(result).to be_nil
      end

      it 'エラーをログに記録する' do
        expect(Rails.logger).to receive(:error).with(/YouTube API server error/)
        described_class.fetch_video_info(youtube_url)
      end
    end

    context 'API認証エラーが発生した場合' do
      before do
        youtube_service = instance_double(Google::Apis::YoutubeV3::YouTubeService)
        allow(Rails.application.config).to receive(:youtube_service).and_return(youtube_service)
        allow(youtube_service).to receive(:list_videos).and_raise(Google::Apis::AuthorizationError.new('Unauthorized'))
      end

      it 'nilを返す' do
        result = described_class.fetch_video_info(youtube_url)
        expect(result).to be_nil
      end

      it 'エラーをログに記録する' do
        expect(Rails.logger).to receive(:error).with(/YouTube API authorization error/)
        described_class.fetch_video_info(youtube_url)
      end
    end

    context '不正なURL形式の場合' do
      before do
        youtube_service = instance_double(Google::Apis::YoutubeV3::YouTubeService)
        allow(Rails.application.config).to receive(:youtube_service).and_return(youtube_service)
        allow(youtube_service).to receive(:list_videos).with('snippet', anything).and_return(double(items: []))
      end

      it 'URIパースエラーで nilを返す' do
        result = described_class.fetch_video_info("https://www.youtube.com/watch?v=abc[def")
        expect(result).to be_nil
      end
    end

    context '複数パラメータを含むyoutube.com URLの場合' do
      let(:url_with_params) { "https://www.youtube.com/watch?v=#{video_id}&list=PLxxx&t=10" }

      it '動画情報を返す' do
        result = described_class.fetch_video_info(url_with_params)

        expect(result).to include(
          title: 'Test Video Title',
          channel_name: 'Test Channel'
        )
      end
    end

    context 'レスポンスのitemsがnilの場合' do
      before do
        youtube_service = instance_double(Google::Apis::YoutubeV3::YouTubeService)
        allow(Rails.application.config).to receive(:youtube_service).and_return(youtube_service)
        response = double(items: nil)
        allow(youtube_service).to receive(:list_videos).and_return(response)
      end

      it 'nilを返す' do
        result = described_class.fetch_video_info(youtube_url)
        expect(result).to be_nil
      end
    end

    # ------------------------------------------
    # チャンネルサムネイル取得のテスト
    # ------------------------------------------
    context 'チャンネルサムネイル取得でエラーが発生した場合' do
      before do
        youtube_service = instance_double(Google::Apis::YoutubeV3::YouTubeService)
        allow(Rails.application.config).to receive(:youtube_service).and_return(youtube_service)

        video_snippet = double(
          title: 'Test Video Title',
          channel_title: 'Test Channel',
          channel_id: channel_id
        )
        video_item = double(snippet: video_snippet)
        video_response = double(items: [video_item])
        allow(youtube_service).to receive(:list_videos).with('snippet', id: video_id).and_return(video_response)

        # チャンネル取得でエラー
        allow(youtube_service).to receive(:list_channels).and_raise(StandardError.new('API Error'))
      end

      it '動画情報を返す（サムネイルはnil）' do
        result = described_class.fetch_video_info(youtube_url)

        expect(result).to include(
          title: 'Test Video Title',
          channel_name: 'Test Channel',
          channel_thumbnail_url: nil
        )
      end

      it 'エラーをログに記録する' do
        expect(Rails.logger).to receive(:warn).with(/Failed to fetch channel thumbnail/)
        described_class.fetch_video_info(youtube_url)
      end
    end

    context 'チャンネルが存在しない場合' do
      before do
        youtube_service = instance_double(Google::Apis::YoutubeV3::YouTubeService)
        allow(Rails.application.config).to receive(:youtube_service).and_return(youtube_service)

        video_snippet = double(
          title: 'Test Video Title',
          channel_title: 'Test Channel',
          channel_id: channel_id
        )
        video_item = double(snippet: video_snippet)
        video_response = double(items: [video_item])
        allow(youtube_service).to receive(:list_videos).with('snippet', id: video_id).and_return(video_response)

        # チャンネルが存在しない
        allow(youtube_service).to receive(:list_channels).and_return(double(items: []))
      end

      it '動画情報を返す（サムネイルはnil）' do
        result = described_class.fetch_video_info(youtube_url)

        expect(result).to include(
          title: 'Test Video Title',
          channel_name: 'Test Channel',
          channel_thumbnail_url: nil
        )
      end
    end

    context 'mediumサムネイルのみの場合' do
      before do
        youtube_service = instance_double(Google::Apis::YoutubeV3::YouTubeService)
        allow(Rails.application.config).to receive(:youtube_service).and_return(youtube_service)

        video_snippet = double(
          title: 'Test Video Title',
          channel_title: 'Test Channel',
          channel_id: channel_id
        )
        video_item = double(snippet: video_snippet)
        video_response = double(items: [video_item])
        allow(youtube_service).to receive(:list_videos).with('snippet', id: video_id).and_return(video_response)

        # defaultがnilでmediumのみ
        medium_thumbnail = double(url: 'https://example.com/medium_thumbnail.jpg')
        channel_thumbnails = double(default: nil, medium: medium_thumbnail)
        channel_snippet = double(thumbnails: channel_thumbnails)
        channel_item = double(snippet: channel_snippet)
        channel_response = double(items: [channel_item])
        allow(youtube_service).to receive(:list_channels).with('snippet', id: channel_id).and_return(channel_response)
      end

      it 'mediumサムネイルURLを返す' do
        result = described_class.fetch_video_info(youtube_url)

        expect(result[:channel_thumbnail_url]).to eq('https://example.com/medium_thumbnail.jpg')
      end
    end
  end

  # ==========================================
  # 動画検索のテスト
  # ==========================================
  # 【何をテストしている？】
  # YouTube検索機能。
  # キーワードで動画を検索し、結果を返す。
  #
  describe '.search_videos' do
    let(:query) { 'Ruby programming' }

    before do
      @youtube_service = instance_double(Google::Apis::YoutubeV3::YouTubeService)
      allow(Rails.application.config).to receive(:youtube_service).and_return(@youtube_service)
    end

    context '検索結果がある場合' do
      before do
        video_id_obj = double(video_id: 'abc123')
        medium_thumbnail = double(url: 'https://example.com/thumbnail.jpg')
        thumbnails = double(medium: medium_thumbnail, default: nil)
        snippet = double(
          title: 'Learn Ruby',
          channel_title: 'Ruby Channel',
          thumbnails: thumbnails
        )
        search_item = double(id: video_id_obj, snippet: snippet)
        search_response = double(items: [search_item])

        allow(@youtube_service).to receive(:list_searches).and_return(search_response)
      end

      it '動画リストを返す' do
        result = described_class.search_videos(query)

        expect(result.length).to eq(1)
        expect(result.first).to include(
          video_id: 'abc123',
          title: 'Learn Ruby',
          channel_name: 'Ruby Channel',
          thumbnail_url: 'https://example.com/thumbnail.jpg',
          youtube_url: 'https://www.youtube.com/watch?v=abc123'
        )
      end
    end

    context 'defaultサムネイルのみの場合' do
      before do
        video_id_obj = double(video_id: 'abc123')
        default_thumbnail = double(url: 'https://example.com/default.jpg')
        thumbnails = double(medium: nil, default: default_thumbnail)
        snippet = double(
          title: 'Learn Ruby',
          channel_title: 'Ruby Channel',
          thumbnails: thumbnails
        )
        search_item = double(id: video_id_obj, snippet: snippet)
        search_response = double(items: [search_item])

        allow(@youtube_service).to receive(:list_searches).and_return(search_response)
      end

      it 'defaultサムネイルURLを返す' do
        result = described_class.search_videos(query)

        expect(result.first[:thumbnail_url]).to eq('https://example.com/default.jpg')
      end
    end

    context 'video_idがないアイテム（チャンネル等）が含まれる場合' do
      before do
        video_id_obj = double(video_id: 'abc123')
        medium_thumbnail = double(url: 'https://example.com/thumbnail.jpg')
        thumbnails = double(medium: medium_thumbnail, default: nil)
        snippet = double(
          title: 'Learn Ruby',
          channel_title: 'Ruby Channel',
          thumbnails: thumbnails
        )
        video_item = double(id: video_id_obj, snippet: snippet)

        # チャンネルアイテム（video_idがnil）
        channel_id_obj = double(video_id: nil)
        channel_item = double(id: channel_id_obj, snippet: snippet)

        search_response = double(items: [video_item, channel_item])
        allow(@youtube_service).to receive(:list_searches).and_return(search_response)
      end

      it '動画のみをフィルタリングして返す' do
        result = described_class.search_videos(query)

        expect(result.length).to eq(1)
        expect(result.first[:video_id]).to eq('abc123')
      end
    end

    # ------------------------------------------
    # 異常系テスト
    # ------------------------------------------
    context 'クエリがnilの場合' do
      it '空配列を返す' do
        result = described_class.search_videos(nil)
        expect(result).to eq([])
      end
    end

    context 'クエリが空の場合' do
      it '空配列を返す' do
        result = described_class.search_videos('')
        expect(result).to eq([])
      end
    end

    context 'YouTube APIサービスが設定されていない場合' do
      before do
        allow(Rails.application.config).to receive(:youtube_service).and_return(nil)
      end

      it '空配列を返す' do
        result = described_class.search_videos(query)
        expect(result).to eq([])
      end
    end

    context 'APIクライアントエラーが発生した場合' do
      before do
        allow(@youtube_service).to receive(:list_searches).and_raise(Google::Apis::ClientError.new('Quota exceeded'))
      end

      it '空配列を返す' do
        result = described_class.search_videos(query)
        expect(result).to eq([])
      end

      it 'エラーをログに記録する' do
        expect(Rails.logger).to receive(:warn).with(/YouTube API search error/)
        described_class.search_videos(query)
      end
    end

    context 'APIサーバーエラーが発生した場合' do
      before do
        allow(@youtube_service).to receive(:list_searches).and_raise(Google::Apis::ServerError.new('Internal Server Error'))
      end

      it '空配列を返す' do
        result = described_class.search_videos(query)
        expect(result).to eq([])
      end

      it 'エラーをログに記録する' do
        expect(Rails.logger).to receive(:error).with(/YouTube API server error/)
        described_class.search_videos(query)
      end
    end

    context 'API認証エラーが発生した場合' do
      before do
        allow(@youtube_service).to receive(:list_searches).and_raise(Google::Apis::AuthorizationError.new('Unauthorized'))
      end

      it '空配列を返す' do
        result = described_class.search_videos(query)
        expect(result).to eq([])
      end

      it 'エラーをログに記録する' do
        expect(Rails.logger).to receive(:error).with(/YouTube API authorization error/)
        described_class.search_videos(query)
      end
    end

    context 'max_resultsを指定した場合' do
      before do
        video_id_obj = double(video_id: 'abc123')
        medium_thumbnail = double(url: 'https://example.com/thumbnail.jpg')
        thumbnails = double(medium: medium_thumbnail, default: nil)
        snippet = double(
          title: 'Learn Ruby',
          channel_title: 'Ruby Channel',
          thumbnails: thumbnails
        )
        search_item = double(id: video_id_obj, snippet: snippet)
        search_response = double(items: [search_item])

        allow(@youtube_service).to receive(:list_searches)
          .with('snippet', q: query, type: 'video', max_results: 5, order: 'relevance')
          .and_return(search_response)
      end

      it '指定した件数で検索する' do
        result = described_class.search_videos(query, max_results: 5)

        expect(result.length).to eq(1)
      end
    end
  end
end
