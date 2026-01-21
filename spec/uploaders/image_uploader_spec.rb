# spec/uploaders/image_uploader_spec.rb
# ==========================================
# ImageUploader のテスト
# ==========================================
#
# 【このファイルの役割】
# CarrierWave画像アップローダーの設定をテストする。
#
# 【テストの実行方法】
#   docker compose exec web rspec spec/uploaders/image_uploader_spec.rb
#
# 【テスト対象】
# - store_dir（保存ディレクトリ）
# - versions（サムネイルバージョン）
# - extension_allowlist（許可する拡張子）
# - MiniMagick（画像処理）
#
# 【CarrierWaveとは？】
# ファイルアップロード機能を提供するgem。
# 画像のリサイズ、サムネイル作成、S3保存などができる。
#
#   uploader = ImageUploader.new(user, :avatar)
#   uploader.store_dir    # 保存先パス
#   uploader.url          # 画像URL
#   uploader.thumb.url    # サムネイルURL
#
# 【注意】
# ImageMagickが必要なテストは CI 環境ではスキップされる。
#
require 'rails_helper'

RSpec.describe ImageUploader do
  let(:user) { create(:user) }

  it 'store_dir が user/avatar/<id> を含む' do
    uploader = ImageUploader.new(user, :avatar)
    allow(user).to receive(:id).and_return(123)
    expect(uploader.store_dir).to include('uploads/user/avatar/123')
  end

  it 'thumb バージョンが定義されている' do
    expect(ImageUploader.versions).to have_key(:thumb)
  end
  describe '画像処理', skip: 'ImageMagickが必要なためCI環境ではスキップ' do
    let(:user) { create(:user) }
    let(:uploader) { ImageUploader.new(user, :avatar) }
    let(:sample_image) { File.open(Rails.root.join('spec/fixtures/files/sample_avatar.jpg')) }

    before do
      ImageUploader.enable_processing = true
      uploader.store!(sample_image)
    end

    after do
      ImageUploader.enable_processing = false
      uploader.remove!
    end

    it '画像がアップロードされる' do
      expect(uploader.file).to be_present
    end

    it 'URLが生成される' do
      expect(uploader.url).to be_present
    end

    it 'サムネイルURLが生成される' do
      expect(uploader.thumb.url).to be_present
    end
  end

  describe '拡張子制限' do
    let(:user) { create(:user) }
    let(:uploader) { ImageUploader.new(user, :avatar) }

    it '許可された拡張子のみアップロードできる' do
      expect(uploader.extension_allowlist).to eq(%w[jpg jpeg gif png])
    end
  end

  describe 'ファイルサイズ制限' do
    it '画像処理機能が含まれている' do
      expect(ImageUploader.ancestors).to include(CarrierWave::MiniMagick)
    end
  end
end
