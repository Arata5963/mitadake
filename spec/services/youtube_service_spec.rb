require 'rails_helper'

RSpec.describe YoutubeService, type: :service, youtube_api: true do
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
        # APIへの呼び出しを許可しない
        youtube_service = instance_double(Google::Apis::YoutubeV3::YouTubeService)
        allow(Rails.application.config).to receive(:youtube_service).and_return(youtube_service)
        # 任意のidで呼ばれる可能性があるので、any_argsでスタブ
        allow(youtube_service).to receive(:list_videos).with('snippet', anything).and_return(double(items: []))
      end

      it 'URIパースエラーで nilを返す' do
        # 不正な文字を含むURL - URI.parseで例外が発生し、rescueでnilを返す
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
  end
end
