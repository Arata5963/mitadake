# frozen_string_literal: true

# app/controllers/api/presigned_urls_controller.rb
# ==========================================
# S3署名付きURLを発行するAPIコントローラー
# ==========================================
#
# 【このクラスの役割】
# フロントエンドがS3に直接画像をアップロードするための
# 「署名付きURL」を発行する。
#
# 【署名付きURL（Presigned URL）とは？】
# 一時的にS3へのアクセス権を付与するURL。
# このURLを使えば、AWSの認証情報なしでS3にアップロードできる。
# 有効期限付きなので、セキュリティ的にも安全。
#
# 【なぜ署名付きURLを使うのか？】
#
#   【従来の方法（サーバー経由）】
#   ブラウザ → Railsサーバー → S3
#   問題: サーバーのメモリ・帯域を消費、遅い
#
#   【署名付きURLを使う方法】
#   1. ブラウザ → Railsサーバー（URL発行のみ）
#   2. ブラウザ → S3（直接アップロード）
#   メリット: サーバー負荷軽減、高速
#
# 【使用フロー】
#
#   1. フロントエンド: POST /api/presigned_urls
#      ↓
#   2. このAPI: 署名付きURLを生成して返す
#      ↓
#   3. フロントエンド: 署名付きURLにPUTリクエスト（画像データ）
#      ↓
#   4. S3: 画像を保存
#      ↓
#   5. フロントエンド: s3_keyをRailsに送信して保存
#
# 【使用場面】
# - アクションプラン作成時のカスタムサムネイル画像
# - 達成記録画像のアップロード
#
module Api
  class PresignedUrlsController < ApplicationController

    # ログイン必須（署名付きURLの発行は認証ユーザーのみ）
    before_action :authenticate_user!

    # ------------------------------------------
    # 署名付きアップロードURL発行
    # ------------------------------------------
    # 【ルート】POST /api/presigned_urls
    #
    # 【リクエストパラメータ】
    # - filename: ファイル名（ログ用、実際の保存名には使わない）
    # - content_type: MIMEタイプ（image/jpeg, image/png, image/webp）
    #
    # 【レスポンス】
    # 成功時:
    # {
    #   "upload_url": "https://s3.amazonaws.com/bucket/...",
    #   "s3_key": "user_thumbnails/123/uuid.jpg"
    # }
    #
    # 失敗時:
    # { "error": "許可されていないファイル形式です" }
    #
    def create
      filename = params[:filename]
      content_type = params[:content_type]

      # 許可されたファイル形式かチェック
      # セキュリティ: 実行可能ファイル等のアップロードを防ぐ
      unless valid_content_type?(content_type)
        render json: { error: "許可されていないファイル形式です" }, status: :unprocessable_entity
        return
      end

      # MIMEタイプから拡張子を決定
      extension = extension_from_content_type(content_type)

      # 【S3キーの生成】
      # 形式: user_thumbnails/ユーザーID/ランダムUUID.拡張子
      # 例: user_thumbnails/123/550e8400-e29b-41d4-a716-446655440000.jpg
      #
      # 【SecureRandom.uuid とは？】
      # 一意な識別子を生成するRubyの標準ライブラリ。
      # ファイル名の衝突を防ぐために使用。
      s3_key = "user_thumbnails/#{current_user.id}/#{SecureRandom.uuid}.#{extension}"

      # 【AWS S3クライアントの初期化】
      # 環境変数からAWSの認証情報を取得して接続。
      # これらは .env や本番環境の環境変数で設定する。
      s3_client = Aws::S3::Client.new(
        region: ENV["AWS_REGION"],
        access_key_id: ENV["AWS_ACCESS_KEY_ID"],
        secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"]
      )

      # 【Presignerの作成】
      # 署名付きURLを生成するためのヘルパークラス
      presigner = Aws::S3::Presigner.new(client: s3_client)

      # 【署名付きURLの生成】
      # :put_object は「アップロード用」という意味
      # expires_in: 300 は「5分間有効」という意味
      upload_url = presigner.presigned_url(
        :put_object,
        bucket: ENV["AWS_BUCKET"],
        key: s3_key,
        content_type: content_type,
        expires_in: 300  # 5分間有効
      )

      # 署名付きURLとS3キーを返す
      # フロントエンドはこのURLにPUTリクエストを送る
      render json: {
        upload_url: upload_url,
        s3_key: s3_key
      }
    end

    private

    # ------------------------------------------
    # 許可されたContent-Typeか判定
    # ------------------------------------------
    # 【何をするメソッド？】
    # アップロードを許可するファイル形式かチェック。
    # セキュリティ対策として、画像ファイルのみ許可。
    #
    # 【許可する形式】
    # - image/jpeg: JPG画像
    # - image/png: PNG画像
    # - image/webp: WebP画像（モダンな形式）
    #
    def valid_content_type?(content_type)
      %w[image/jpeg image/png image/webp].include?(content_type)
    end

    # ------------------------------------------
    # Content-Typeから拡張子を決定
    # ------------------------------------------
    # 【何をするメソッド？】
    # MIMEタイプからファイル拡張子を返す。
    # S3に保存する際のファイル名に使用。
    #
    def extension_from_content_type(content_type)
      case content_type
      when "image/jpeg" then "jpg"
      when "image/png" then "png"
      when "image/webp" then "webp"
      else "jpg"  # デフォルト
      end
    end
  end
end
