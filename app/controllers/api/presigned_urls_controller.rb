# frozen_string_literal: true

# S3署名付きURL発行APIコントローラー
# フロントエンドがS3に直接アップロードするためのURLを発行

module Api
  class PresignedUrlsController < ApplicationController
    before_action :authenticate_user!  # ログイン必須

    # 署名付きアップロードURL発行（POST /api/presigned_urls）
    def create
      filename = params[:filename]          # ファイル名（ログ用）
      content_type = params[:content_type]  # MIMEタイプ

      unless valid_content_type?(content_type)                                            # ファイル形式チェック
        render json: { error: "許可されていないファイル形式です" }, status: :unprocessable_entity
        return
      end

      extension = extension_from_content_type(content_type)                               # 拡張子を決定
      s3_key = "user_thumbnails/#{current_user.id}/#{SecureRandom.uuid}.#{extension}"     # S3キー生成

      s3_client = Aws::S3::Client.new(                                                    # S3クライアント初期化
        region: ENV["AWS_REGION"],
        access_key_id: ENV["AWS_ACCESS_KEY_ID"],
        secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"]
      )

      presigner = Aws::S3::Presigner.new(client: s3_client)                               # Presigner作成

      upload_url = presigner.presigned_url(                                               # 署名付きURL生成
        :put_object,
        bucket: ENV["AWS_BUCKET"],
        key: s3_key,
        content_type: content_type,
        expires_in: 300                                                                   # 5分間有効
      )

      render json: { upload_url: upload_url, s3_key: s3_key }                             # URLとキーを返す
    end

    private

    # 許可されたContent-Typeか判定
    def valid_content_type?(content_type)
      %w[image/jpeg image/png image/webp].include?(content_type)  # 画像のみ許可
    end

    # Content-Typeから拡張子を決定
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
