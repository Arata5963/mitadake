# frozen_string_literal: true

# app/controllers/api/presigned_urls_controller.rb
# S3への直接アップロード用の署名付きURLを発行するAPIコントローラー
#
# 使用場面:
# - アクションプラン作成時のカスタムサムネイル画像
# - 達成記録画像のアップロード
#
# フロー:
# 1. フロントエンドがこのAPIを呼び出して署名付きURLを取得
# 2. フロントエンドがその署名付きURLを使ってS3に直接アップロード
# 3. アップロード完了後、s3_keyをサーバーに送信して保存
#
# メリット:
# - サーバーを経由しないため高速
# - サーバーのメモリ/帯域を節約
module Api
  class PresignedUrlsController < ApplicationController
    before_action :authenticate_user!

    # 署名付きアップロードURL発行
    # @route POST /api/presigned_urls
    # @param filename [String] ファイル名（未使用だがログ用に受け取り可）
    # @param content_type [String] MIMEタイプ（image/jpeg, image/png, image/webp）
    # @return [JSON] { upload_url: "署名付きURL", s3_key: "保存先キー" }
    def create
      filename = params[:filename]
      content_type = params[:content_type]

      # 許可されたファイル形式かチェック
      unless valid_content_type?(content_type)
        render json: { error: "許可されていないファイル形式です" }, status: :unprocessable_entity
        return
      end

      extension = extension_from_content_type(content_type)

      # S3キー: user_thumbnails/ユーザーID/ランダムUUID.拡張子
      s3_key = "user_thumbnails/#{current_user.id}/#{SecureRandom.uuid}.#{extension}"

      # AWS S3クライアントを初期化
      s3_client = Aws::S3::Client.new(
        region: ENV["AWS_REGION"],
        access_key_id: ENV["AWS_ACCESS_KEY_ID"],
        secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"]
      )
      presigner = Aws::S3::Presigner.new(client: s3_client)

      # PUT用の署名付きURL（5分間有効）
      upload_url = presigner.presigned_url(
        :put_object,
        bucket: ENV["AWS_BUCKET"],
        key: s3_key,
        content_type: content_type,
        expires_in: 300
      )

      render json: {
        upload_url: upload_url,
        s3_key: s3_key
      }
    end

    private

    # 許可されたContent-Typeか判定
    # @param content_type [String] MIMEタイプ
    # @return [Boolean]
    def valid_content_type?(content_type)
      %w[image/jpeg image/png image/webp].include?(content_type)
    end

    # Content-Typeから拡張子を決定
    # @param content_type [String] MIMEタイプ
    # @return [String] 拡張子
    def extension_from_content_type(content_type)
      case content_type
      when "image/jpeg" then "jpg"
      when "image/png" then "png"
      when "image/webp" then "webp"
      else "jpg"
      end
    end
  end
end
