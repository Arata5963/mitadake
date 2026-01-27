# 画像アップローダー（CarrierWave）
# User#avatar等の画像アップロード・リサイズ処理を定義

class ImageUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick  # 画像処理メソッドを有効化

  # 保存先ディレクトリを動的に生成
  def store_dir
    "public/uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"  # 例: public/uploads/user/avatar/123
  end

  # 許可する拡張子（画像ファイルのみ）
  def extension_allowlist
    %w[jpg jpeg gif png]
  end

  process resize_to_limit: [ 2000, 2000 ]  # アップロード時に最大2000x2000にリサイズ

  # サムネイル版を自動生成（@user.avatar.thumb.url で取得）
  version :thumb do
    process resize_to_fit: [ 300, 300 ]
  end
end
