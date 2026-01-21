# spec/helpers/application_helper_spec.rb
require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe '#default_meta_tags' do
    before do
      # request オブジェクトをモック
      allow(helper).to receive(:request).and_return(
        double(
          original_url: 'http://example.com/test',
          base_url: 'http://example.com'
        )
      )
    end

    let(:meta) { helper.default_meta_tags }

    it 'サイト名を返す' do
      expect(meta[:site]).to eq('mitadake?')
    end

    it 'タイトルはデフォルトで空文字列（ページごとに設定される）' do
      expect(meta[:title]).to eq('')
    end

    it 'ディスクリプションを返す' do
      expect(meta[:description]).to include('YouTube')
      expect(meta[:description]).to include('アクション')
    end

    it 'キーワードを返す' do
      expect(meta[:keywords]).to include('YouTube')
    end

    it 'canonical URL を返す' do
      expect(meta[:canonical]).to eq('http://example.com/test')
    end

    it 'OG タグを含む（URL/画像/型）' do
      expect(meta[:og]).to be_a(Hash)
      expect(meta[:og][:site_name]).to eq('mitadake?')
      expect(meta[:og][:type]).to eq('website')
      expect(meta[:og][:url]).to eq('http://example.com/test')
      expect(meta[:og][:image]).to eq('http://example.com/ogp-image.png')
    end

    it 'Twitter カードタグを含む（画像URL含む）' do
      expect(meta[:twitter]).to be_a(Hash)
      expect(meta[:twitter][:card]).to eq('summary_large_image')
      expect(meta[:twitter][:image]).to eq('http://example.com/ogp-image.png')
    end

    it 'メタの基本キー（reverse/charset/separator）を含む' do
      expect(meta[:reverse]).to eq(true)
      expect(meta[:charset]).to eq('utf-8')
      expect(meta[:separator]).to eq('|')
    end

    it 'OG/Twitter のタイトル・ディスクリプションはシンボル委譲である（view側で解決）' do
      expect(meta[:og][:title]).to eq(:title)
      expect(meta[:twitter][:title]).to eq(:title)
      expect(meta[:twitter][:description]).to eq(:description)
    end
  end
end
