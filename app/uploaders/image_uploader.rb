# app/uploaders/image_uploader.rb
# ==========================================
# 画像アップローダー（CarrierWave）
# ==========================================
#
# 【このファイルの役割】
# CarrierWaveを使った画像アップロード処理を定義。
# アップロード、リサイズ、保存先の設定などを行う。
#
# 【CarrierWaveとは？】
# Railsで最もよく使われるファイルアップロードライブラリ。
# Active Storageより設定の自由度が高い。
#
# 【使用場所】
# - User#avatar（プロフィール画像）
#
# 【機能】
# 1. S3へのアップロード（本番環境）
# 2. アップロード時に自動リサイズ（最大2000x2000px）
# 3. サムネイル版を自動生成（300x300px）
# 4. 許可拡張子の制限（jpg, jpeg, gif, png）
#
# 【依存ライブラリ】
# - CarrierWave gem: ファイルアップロードの基盤
# - MiniMagick gem: ImageMagickのRubyラッパー
# - ImageMagick: 画像処理ソフト（Dockerfileでインストール済み）
#
# 【モデルでの使い方】
#   class User < ApplicationRecord
#     mount_uploader :avatar, ImageUploader
#   end
#
# 【画像URLの取得】
#   @user.avatar.url         # 元画像のURL
#   @user.avatar.thumb.url   # サムネイルのURL
#
class ImageUploader < CarrierWave::Uploader::Base
  # ------------------------------------------
  # MiniMagick を読み込み
  # ------------------------------------------
  # これにより resize_to_limit, resize_to_fit などの
  # 画像処理メソッドが使えるようになる
  #
  include CarrierWave::MiniMagick

  # ------------------------------------------
  # ストレージ設定
  # ------------------------------------------
  # config/initializers/carrierwave.rb で設定済み
  # - 開発環境: :file（ローカルファイルシステム）
  # - 本番環境: :fog（S3）
  #

  # ------------------------------------------
  # 保存先ディレクトリ
  # ------------------------------------------
  # 【何をするメソッド？】
  # S3やローカルでのファイル保存パスを動的に生成。
  #
  # 【生成されるパス例】
  # uploads/user/avatar/123/filename.jpg
  #
  # 【各部分の意味】
  # - model.class.to_s.underscore → "User" を "user" に変換
  # - mounted_as → マウント名（:avatar）
  # - model.id → ユーザーID
  #
  def store_dir
    "public/uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  # ------------------------------------------
  # 許可する拡張子
  # ------------------------------------------
  # 【何をするメソッド？】
  # アップロードを許可するファイル拡張子を制限。
  # セキュリティ対策として画像ファイルのみを許可。
  #
  # 【なぜ制限が必要？】
  # 悪意のあるファイル（.exe, .php など）の
  # アップロードを防ぐため。
  #
  # 【%w[] とは？】
  # 文字列配列を簡潔に書く Ruby の記法
  # %w[jpg jpeg] は ["jpg", "jpeg"] と同じ
  #
  def extension_allowlist
    %w[jpg jpeg gif png]
  end

  # ------------------------------------------
  # アップロード時の画像処理
  # ------------------------------------------
  # 【何をするメソッド？】
  # 元画像が巨大すぎる場合に自動でリサイズ。
  # サーバーの容量とパフォーマンスを守る安全装置。
  #
  # 【resize_to_limit とは？】
  # 指定サイズを超える場合のみリサイズ。
  # アスペクト比は維持される。
  # 指定サイズより小さい画像はそのまま。
  #
  process resize_to_limit: [ 2000, 2000 ]

  # ------------------------------------------
  # サムネイル版の自動生成
  # ------------------------------------------
  # 【何をするメソッド？】
  # 元画像とは別に、小さいサムネイル版を自動生成。
  # ユーザーリストやプレビュー表示用。
  #
  # 【version とは？】
  # CarrierWaveの機能で、元画像の派生版を作成。
  # 1つのアップロードで複数サイズを生成できる。
  #
  # 【resize_to_fit とは？】
  # 指定サイズ内に収まるようにリサイズ。
  # アスペクト比を維持。
  # resize_to_limit と違い、小さい画像でも適用される。
  #
  version :thumb do
    process resize_to_fit: [ 300, 300 ]
  end
  # 使用例: @user.avatar.thumb.url でサムネイルURLを取得
end
