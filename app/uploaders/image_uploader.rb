# app/uploaders/image_uploader.rb
# CarrierWaveを使った画像アップロード処理を定義
#
# 使用場所:
# - User#avatar（プロフィール画像）
#
# 機能:
# - アップロード時に自動リサイズ（最大2000x2000px）
# - サムネイル版を自動生成（300x300px）
# - 許可拡張子の制限（jpg, jpeg, gif, png）
# - S3へのアップロード（carrierwave-fog経由）
#
# 依存:
# - CarrierWave gem
# - MiniMagick gem（ImageMagickラッパー）
# - ImageMagick（Dockerfileでインストール済み）
class ImageUploader < CarrierWave::Uploader::Base
  # MiniMagickライブラリを読み込み（画像のリサイズ・変換処理を可能にする）
  include CarrierWave::MiniMagick

  # ファイル保存先をfog（クラウドストレージ）に指定
  # config/initializers/carrierwave.rbの設定によりS3に保存される

  # S3内でのファイル保存ディレクトリを動的に決定
  # 例: uploads/user/avatar/123 (ユーザーID123のアバター画像の場合)
  def store_dir
    "public/uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
    # model.class.to_s.underscore: モデル名を小文字アンダースコア形式に変換（User → user）
    # mounted_as: マウントされたフィールド名（例: avatar, image）
    # model.id: レコードの一意識別子
  end

  # アップロード可能なファイル拡張子を制限
  # セキュリティ対策として画像ファイルのみを許可
  def extension_allowlist
    %w[jpg jpeg gif png]  # 配列形式で許可する拡張子を列挙
  end

  # アップロード時に自動実行される画像処理
  # 元画像が巨大すぎる場合の安全装置として最大サイズを制限
  process resize_to_limit: [ 2000, 2000 ]  # 幅2000px、高さ2000pxを上限に自動リサイズ

  # 元画像とは別にサムネイル版を自動生成
  # ユーザーリスト表示やプレビュー用途で使用
  version :thumb do
    # resize_to_fit: アスペクト比を保持しつつ指定サイズ内に収める
    process resize_to_fit: [ 300, 300 ]  # 300x300px以内のサムネイルを生成
  end
  # 使用例: @user.avatar.thumb.url でサムネイルURLを取得可能
end
