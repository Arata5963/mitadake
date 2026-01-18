# frozen_string_literal: true

# AI生成サムネイルをバックグラウンドで生成するジョブ
class ThumbnailGenerationJob < ApplicationJob
  queue_as :default

  # リトライ設定（生成失敗時は最大3回リトライ）
  retry_on StandardError, wait: 30.seconds, attempts: 3

  def perform(post_entry_id)
    post_entry = PostEntry.find_by(id: post_entry_id)
    return if post_entry.nil?
    return if post_entry.thumbnail_url.present? # 既に生成済み

    Rails.logger.info("[ThumbnailGenerationJob] Starting for PostEntry##{post_entry_id}")

    # 1. 画像を生成
    result = HuggingfaceService.generate_thumbnail(post_entry.content)

    unless result[:success]
      Rails.logger.error("[ThumbnailGenerationJob] Generation failed: #{result[:error]}")

      # モデルがロード中の場合はリトライ
      if result[:retry_after]
        raise StandardError, "Model loading, retry after #{result[:retry_after]}s"
      end

      return # 生成失敗時はフォールバック（YouTube サムネイル）を使う
    end

    # 2. S3にアップロード
    image_url = upload_to_s3(post_entry, result[:image_data])

    unless image_url
      Rails.logger.error("[ThumbnailGenerationJob] S3 upload failed")
      return
    end

    # 3. URLを保存
    post_entry.update!(thumbnail_url: image_url)
    Rails.logger.info("[ThumbnailGenerationJob] Completed for PostEntry##{post_entry_id}: #{image_url}")
  end

  private

  def upload_to_s3(post_entry, base64_data)
    require "aws-sdk-s3"

    # Base64をデコード
    image_data = Base64.decode64(base64_data)

    # S3クライアント
    s3 = Aws::S3::Client.new(
      region: ENV["AWS_REGION"],
      access_key_id: ENV["AWS_ACCESS_KEY_ID"],
      secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"]
    )

    # ファイル名を生成
    filename = "thumbnails/#{post_entry.id}/#{SecureRandom.uuid}.png"

    # アップロード（ACLは使用せず、バケットポリシーで公開設定）
    s3.put_object(
      bucket: ENV["AWS_BUCKET"],
      key: filename,
      body: image_data,
      content_type: "image/png"
    )

    # S3キーを返す（署名付きURLは表示時に生成）
    filename
  rescue Aws::S3::Errors::ServiceError => e
    Rails.logger.error("[ThumbnailGenerationJob] S3 error: #{e.message}")
    nil
  end
end
