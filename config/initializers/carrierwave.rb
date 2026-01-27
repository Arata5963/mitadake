# CarrierWave設定ファイル
# 画像アップロードの保存先（テスト:ローカル、本番:S3）を設定

CarrierWave.configure do |config|
  if Rails.env.test?
    config.storage = :file                    # ローカル保存
    config.root = Rails.root.join("tmp")      # tmpディレクトリに保存
  else
    config.storage = :fog                     # クラウド保存（S3）
    config.fog_provider = "fog/aws"           # AWSを使用

    config.fog_credentials = {
      provider:              "AWS",
      aws_access_key_id:     ENV["AWS_ACCESS_KEY_ID"],      # IAM認証情報
      aws_secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"],
      region:                ENV["AWS_REGION"]
    }

    config.fog_directory = ENV["AWS_BUCKET"]  # S3バケット名
    config.fog_public = false                 # 署名付きURLでのみアクセス可能
    config.fog_attributes = {}                # ACL無効化（新S3設定推奨）
  end
end
