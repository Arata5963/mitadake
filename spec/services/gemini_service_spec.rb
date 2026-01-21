require 'rails_helper'

RSpec.describe GeminiService, type: :service do
  let(:api_key) { 'test_api_key' }
  let(:video_id) { 'test_video_id' }
  let(:title) { 'テスト動画タイトル' }
  let(:description) { 'テスト動画の説明文です' }
  let(:gemini_api_url) { "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=#{api_key}" }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('GEMINI_API_KEY').and_return(api_key)
  end

  describe '.suggest_action_plans' do
    let(:success_response) do
      {
        'candidates' => [
          {
            'content' => {
              'parts' => [
                {
                  'text' => '{"action_plans": ["【やってみた】朝5時起きを実践した結果", "【検証】読書メモをNotionに記録してみた", "【実践】部屋の断捨離に挑戦してみた"]}'
                }
              ]
            }
          }
        ]
      }
    end

    context 'APIキーが設定されていない場合' do
      before do
        allow(ENV).to receive(:[]).with('GEMINI_API_KEY').and_return(nil)
      end

      it 'エラーを返す' do
        result = described_class.suggest_action_plans(video_id: video_id, title: title)
        expect(result[:success]).to be false
        expect(result[:error]).to eq('Gemini APIキーが設定されていません')
      end
    end

    context 'video_idが空の場合' do
      it 'エラーを返す' do
        result = described_class.suggest_action_plans(video_id: '', title: title)
        expect(result[:success]).to be false
        expect(result[:error]).to eq('動画IDがありません')
      end
    end

    context '字幕が取得できた場合' do
      before do
        allow(TranscriptService).to receive(:fetch_with_status).and_return({
          success: true,
          transcript: '字幕テキストです。' * 50
        })
        stub_request(:post, gemini_api_url).to_return(
          status: 200,
          body: success_response.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
      end

      it 'アクションプランを返す' do
        result = described_class.suggest_action_plans(video_id: video_id, title: title)
        expect(result[:success]).to be true
        expect(result[:action_plans]).to be_an(Array)
        expect(result[:action_plans].length).to eq(3)
      end
    end

    context '字幕が短い場合（タイトル＋説明文から生成）' do
      before do
        allow(TranscriptService).to receive(:fetch_with_status).and_return({
          success: true,
          transcript: '短い字幕'
        })
        stub_request(:post, gemini_api_url).to_return(
          status: 200,
          body: success_response.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
      end

      it 'アクションプランを返す' do
        result = described_class.suggest_action_plans(video_id: video_id, title: title, description: description)
        expect(result[:success]).to be true
        expect(result[:action_plans]).to be_an(Array)
      end
    end

    context '字幕取得に失敗した場合' do
      before do
        allow(TranscriptService).to receive(:fetch_with_status).and_return({
          success: false,
          error: '字幕が見つかりません'
        })
        stub_request(:post, gemini_api_url).to_return(
          status: 200,
          body: success_response.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
      end

      it 'タイトルベースでアクションプランを生成する' do
        result = described_class.suggest_action_plans(video_id: video_id, title: title)
        expect(result[:success]).to be true
      end
    end

    context 'APIがエラーレスポンスを返した場合' do
      before do
        allow(TranscriptService).to receive(:fetch_with_status).and_return({
          success: false
        })
        stub_request(:post, gemini_api_url).to_return(
          status: 200,
          body: { 'error' => { 'message' => 'Invalid API key' } }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
      end

      it 'エラーを返す' do
        result = described_class.suggest_action_plans(video_id: video_id, title: title)
        expect(result[:success]).to be false
        expect(result[:error]).to include('失敗')
      end
    end

    context 'レート制限エラーの場合' do
      before do
        allow(TranscriptService).to receive(:fetch_with_status).and_return({
          success: false
        })
        stub_request(:post, gemini_api_url).to_return(
          status: 200,
          body: { 'error' => { 'message' => '429 quota exceeded' } }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
      end

      it 'レート制限エラーを返す' do
        result = described_class.suggest_action_plans(video_id: video_id, title: title)
        expect(result[:success]).to be false
        expect(result[:error]).to include('混み合っています')
        expect(result[:error_type]).to eq('rate_limit')
      end
    end

    context 'レスポンスにテキストがない場合' do
      before do
        allow(TranscriptService).to receive(:fetch_with_status).and_return({
          success: false
        })
        stub_request(:post, gemini_api_url).to_return(
          status: 200,
          body: { 'candidates' => [{ 'content' => { 'parts' => [{ 'text' => '' }] } }] }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
      end

      it 'エラーを返す' do
        result = described_class.suggest_action_plans(video_id: video_id, title: title)
        expect(result[:success]).to be false
        expect(result[:error]).to include('生成できませんでした')
      end
    end

    context 'JSONパースに失敗した場合' do
      before do
        allow(TranscriptService).to receive(:fetch_with_status).and_return({
          success: false
        })
        stub_request(:post, gemini_api_url).to_return(
          status: 200,
          body: { 'candidates' => [{ 'content' => { 'parts' => [{ 'text' => '{invalid json}' }] } }] }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
      end

      it 'エラーを返す' do
        result = described_class.suggest_action_plans(video_id: video_id, title: title)
        expect(result[:success]).to be false
        expect(result[:error]).to include('解析に失敗')
      end
    end

    context 'アクションプランが空の場合' do
      before do
        allow(TranscriptService).to receive(:fetch_with_status).and_return({
          success: false
        })
        stub_request(:post, gemini_api_url).to_return(
          status: 200,
          body: { 'candidates' => [{ 'content' => { 'parts' => [{ 'text' => '{"action_plans": []}' }] } }] }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
      end

      it 'エラーを返す' do
        result = described_class.suggest_action_plans(video_id: video_id, title: title)
        expect(result[:success]).to be false
        expect(result[:error]).to include('見つかりませんでした')
      end
    end

    context 'HTTP例外が発生した場合' do
      before do
        allow(TranscriptService).to receive(:fetch_with_status).and_return({
          success: false
        })
        stub_request(:post, gemini_api_url).to_raise(StandardError.new('Connection refused'))
      end

      it 'エラーを返す' do
        result = described_class.suggest_action_plans(video_id: video_id, title: title)
        expect(result[:success]).to be false
        expect(result[:error]).to include('失敗しました')
      end
    end

    context 'アクションプランが3個以上ある場合' do
      before do
        allow(TranscriptService).to receive(:fetch_with_status).and_return({
          success: false
        })
        many_plans_response = {
          'candidates' => [
            {
              'content' => {
                'parts' => [
                  {
                    'text' => '{"action_plans": ["プラン1", "プラン2", "プラン3", "プラン4", "プラン5"]}'
                  }
                ]
              }
            }
          ]
        }
        stub_request(:post, gemini_api_url).to_return(
          status: 200,
          body: many_plans_response.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
      end

      it '3個に制限される' do
        result = described_class.suggest_action_plans(video_id: video_id, title: title)
        expect(result[:success]).to be true
        expect(result[:action_plans].length).to eq(3)
      end
    end
  end

  describe '.convert_to_youtube_title' do
    let(:action_plan) { '読書メモをNotionに記録する' }
    let(:success_response) do
      {
        'candidates' => [
          {
            'content' => {
              'parts' => [
                {
                  'text' => '{"title": "【やってみた】読書メモをNotionに記録した結果"}'
                }
              ]
            }
          }
        ]
      }
    end

    context 'APIキーが設定されていない場合' do
      before do
        allow(ENV).to receive(:[]).with('GEMINI_API_KEY').and_return(nil)
      end

      it 'エラーを返す' do
        result = described_class.convert_to_youtube_title(action_plan)
        expect(result[:success]).to be false
        expect(result[:error]).to eq('Gemini APIキーが設定されていません')
      end
    end

    context 'アクションプランが空の場合' do
      it 'エラーを返す' do
        result = described_class.convert_to_youtube_title('')
        expect(result[:success]).to be false
        expect(result[:error]).to eq('アクションプランがありません')
      end
    end

    context '正常にタイトルが生成された場合' do
      before do
        stub_request(:post, gemini_api_url).to_return(
          status: 200,
          body: success_response.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
      end

      it 'タイトルを返す' do
        result = described_class.convert_to_youtube_title(action_plan)
        expect(result[:success]).to be true
        expect(result[:title]).to include('やってみた')
      end
    end

    context 'APIがエラーレスポンスを返した場合' do
      before do
        stub_request(:post, gemini_api_url).to_return(
          status: 200,
          body: { 'error' => { 'message' => 'Invalid API key' } }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
      end

      it 'エラーを返す' do
        result = described_class.convert_to_youtube_title(action_plan)
        expect(result[:success]).to be false
        expect(result[:error]).to include('失敗')
      end
    end

    context 'レート制限エラーの場合' do
      before do
        stub_request(:post, gemini_api_url).to_return(
          status: 200,
          body: { 'error' => { 'message' => '429 rate limit' } }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
      end

      it 'レート制限エラーを返す' do
        result = described_class.convert_to_youtube_title(action_plan)
        expect(result[:success]).to be false
        expect(result[:error]).to include('混み合っています')
      end
    end

    context 'レスポンスにテキストがない場合' do
      before do
        stub_request(:post, gemini_api_url).to_return(
          status: 200,
          body: { 'candidates' => [{ 'content' => { 'parts' => [{ 'text' => '' }] } }] }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
      end

      it 'エラーを返す' do
        result = described_class.convert_to_youtube_title(action_plan)
        expect(result[:success]).to be false
        expect(result[:error]).to include('生成できませんでした')
      end
    end

    context 'JSONにtitleがない場合' do
      before do
        stub_request(:post, gemini_api_url).to_return(
          status: 200,
          body: { 'candidates' => [{ 'content' => { 'parts' => [{ 'text' => '{"other": "value"}' }] } }] }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
      end

      it 'エラーを返す' do
        result = described_class.convert_to_youtube_title(action_plan)
        expect(result[:success]).to be false
        expect(result[:error]).to include('見つかりませんでした')
      end
    end

    context 'JSONパースに失敗した場合' do
      before do
        stub_request(:post, gemini_api_url).to_return(
          status: 200,
          body: { 'candidates' => [{ 'content' => { 'parts' => [{ 'text' => 'not json at all' }] } }] }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
      end

      it 'エラーを返す' do
        result = described_class.convert_to_youtube_title(action_plan)
        expect(result[:success]).to be false
        expect(result[:error]).to include('解析に失敗')
      end
    end

    context 'HTTP例外が発生した場合' do
      before do
        stub_request(:post, gemini_api_url).to_raise(StandardError.new('Network error'))
      end

      it 'エラーを返す' do
        result = described_class.convert_to_youtube_title(action_plan)
        expect(result[:success]).to be false
        expect(result[:error]).to include('失敗しました')
      end
    end
  end
end
