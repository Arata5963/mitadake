class ThumbnailUploader < CarrierWave::Uploader::Base
  # AI生成サムネイル用アップローダー

  # S3内でのファイル保存ディレクトリ
  def store_dir
    "public/uploads/thumbnails/#{model.id}"
  end

  # アップロード可能なファイル拡張子
  def extension_allowlist
    %w[jpg jpeg png webp]
  end

  # デフォルトのファイル名
  def filename
    "thumbnail_#{secure_token}.png" if original_filename.present?
  end

  private

  # ユニークなトークンを生成
  def secure_token
    var = :"@#{mounted_as}_secure_token"
    model.instance_variable_get(var) || model.instance_variable_set(var, SecureRandom.uuid)
  end
end
