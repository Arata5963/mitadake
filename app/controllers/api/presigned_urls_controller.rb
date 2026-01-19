# frozen_string_literal: true

module Api
  class PresignedUrlsController < ApplicationController
    before_action :authenticate_user!

    def create
      filename = params[:filename]
      content_type = params[:content_type]

      # バリデーション
      unless valid_content_type?(content_type)
        render json: { error: "許可されていないファイル形式です" }, status: :unprocessable_entity
        return
      end

      # 拡張子を決定
      extension = extension_from_content_type(content_type)

      # S3キーを生成（ユーザーごとにフォルダ分け）
      s3_key = "user_thumbnails/#{current_user.id}/#{SecureRandom.uuid}.#{extension}"

      # 署名付きPUT URLを生成
      s3_client = Aws::S3::Client.new(
        region: ENV["AWS_REGION"],
        access_key_id: ENV["AWS_ACCESS_KEY_ID"],
        secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"]
      )
      presigner = Aws::S3::Presigner.new(client: s3_client)

      upload_url = presigner.presigned_url(
        :put_object,
        bucket: ENV["AWS_BUCKET"],
        key: s3_key,
        content_type: content_type,
        expires_in: 300 # 5分間有効
      )

      render json: {
        upload_url: upload_url,
        s3_key: s3_key
      }
    end

    private

    def valid_content_type?(content_type)
      %w[image/jpeg image/png image/webp].include?(content_type)
    end

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
