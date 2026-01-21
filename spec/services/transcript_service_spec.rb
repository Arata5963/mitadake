# spec/services/transcript_service_spec.rb
# ==========================================
# TranscriptService のテスト
# ==========================================
#
# 【このファイルの役割】
# YouTube動画の字幕取得サービスをテストする。
# Pythonスクリプトを呼び出して字幕を取得する処理。
#
# 【テストの実行方法】
#   docker compose exec web rspec spec/services/transcript_service_spec.rb
#
# 【テスト対象】
# - fetch_with_status（字幕取得）
#   - 正常系（字幕取得成功）
#   - 異常系（空のvideo_id、スクリプトエラー、JSONパースエラー）
#
# 【外部プロセス呼び出しのモック】
# Open3.capture3 をモック化してPythonスクリプト呼び出しをシミュレート。
#
#   allow(Open3).to receive(:capture3).and_return([output, '', status])
#
# 【instance_double とは？】
# RSpecのモック機能。指定したクラスのインスタンスを模倣する。
# 実際のメソッドと異なるメソッドを呼ぶとエラーになるため安全。
#
#   status = instance_double(Process::Status, success?: true)
#
require 'rails_helper'

RSpec.describe TranscriptService, type: :service do
  describe '.fetch_with_status' do
    let(:video_id) { 'test_video_id' }

    context 'video_idが空の場合' do
      it 'エラーを返す' do
        result = described_class.fetch_with_status('')
        expect(result[:success]).to be false
        expect(result[:error]).to eq('動画IDがありません')
      end

      it 'nilの場合もエラーを返す' do
        result = described_class.fetch_with_status(nil)
        expect(result[:success]).to be false
        expect(result[:error]).to eq('動画IDがありません')
      end
    end

    context 'スクリプト実行が成功した場合' do
      let(:transcript_data) do
        [
          { 'text' => 'こんにちは', 'start' => 0.0, 'duration' => 1.5 },
          { 'text' => '今日は天気がいいですね', 'start' => 1.5, 'duration' => 2.0 }
        ]
      end
      let(:success_output) do
        { 'success' => true, 'transcript' => transcript_data }.to_json
      end

      before do
        status = instance_double(Process::Status, success?: true)
        allow(Open3).to receive(:capture3).and_return([success_output, '', status])
      end

      it '字幕テキストを返す' do
        result = described_class.fetch_with_status(video_id)
        expect(result[:success]).to be true
        expect(result[:transcript]).to include('こんにちは')
        expect(result[:transcript]).to include('今日は天気がいいですね')
      end

      it '字幕が改行で結合されている' do
        result = described_class.fetch_with_status(video_id)
        expect(result[:transcript]).to eq("こんにちは\n今日は天気がいいですね")
      end
    end

    context 'スクリプトがエラーを返した場合' do
      let(:error_output) do
        { 'success' => false, 'error' => '字幕が見つかりません' }.to_json
      end

      before do
        status = instance_double(Process::Status, success?: true)
        allow(Open3).to receive(:capture3).and_return([error_output, '', status])
      end

      it 'エラーメッセージを返す' do
        result = described_class.fetch_with_status(video_id)
        expect(result[:success]).to be false
        expect(result[:error]).to eq('字幕が見つかりません')
      end
    end

    context 'スクリプトがエラーメッセージなしで失敗した場合' do
      let(:error_output) do
        { 'success' => false }.to_json
      end

      before do
        status = instance_double(Process::Status, success?: true)
        allow(Open3).to receive(:capture3).and_return([error_output, '', status])
      end

      it 'デフォルトのエラーメッセージを返す' do
        result = described_class.fetch_with_status(video_id)
        expect(result[:success]).to be false
        expect(result[:error]).to eq('字幕取得に失敗しました')
      end
    end

    context 'スクリプト実行が失敗した場合（非ゼロ終了コード）' do
      before do
        status = instance_double(Process::Status, success?: false)
        allow(Open3).to receive(:capture3).and_return(['', 'Python error', status])
      end

      it 'エラーを返す' do
        result = described_class.fetch_with_status(video_id)
        expect(result[:success]).to be false
        expect(result[:error]).to eq('字幕取得に失敗しました')
      end
    end

    context 'JSONパースエラーの場合' do
      before do
        status = instance_double(Process::Status, success?: true)
        allow(Open3).to receive(:capture3).and_return(['invalid json', '', status])
      end

      it 'エラーを返す' do
        result = described_class.fetch_with_status(video_id)
        expect(result[:success]).to be false
        expect(result[:error]).to eq('字幕取得に失敗しました')
      end
    end

    context '例外が発生した場合' do
      before do
        allow(Open3).to receive(:capture3).and_raise(StandardError.new('Connection failed'))
      end

      it 'エラーを返す' do
        result = described_class.fetch_with_status(video_id)
        expect(result[:success]).to be false
        expect(result[:error]).to eq('字幕取得に失敗しました')
      end
    end

    context '字幕データが空の場合' do
      let(:empty_output) do
        { 'success' => true, 'transcript' => [] }.to_json
      end

      before do
        status = instance_double(Process::Status, success?: true)
        allow(Open3).to receive(:capture3).and_return([empty_output, '', status])
      end

      it '空配列の場合はnilを返す' do
        result = described_class.fetch_with_status(video_id)
        expect(result[:success]).to be true
        # blank?チェックにより空配列はnilになる
        expect(result[:transcript]).to be_nil
      end
    end

    context '字幕データがnilの場合' do
      let(:nil_transcript_output) do
        { 'success' => true, 'transcript' => nil }.to_json
      end

      before do
        status = instance_double(Process::Status, success?: true)
        allow(Open3).to receive(:capture3).and_return([nil_transcript_output, '', status])
      end

      it 'nilを返す' do
        result = described_class.fetch_with_status(video_id)
        expect(result[:success]).to be true
        expect(result[:transcript]).to be_nil
      end
    end
  end
end
