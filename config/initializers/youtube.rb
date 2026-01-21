# frozen_string_literal: true

# config/initializers/youtube.rb
# ==========================================
# YouTube Data API v3 設定ファイル
# ==========================================
#
# 【このファイルの役割】
# YouTube Data APIのクライアントを初期化して
# アプリ全体で使えるようにする。
#
# 【YouTube Data API v3とは？】
# YouTubeの情報をプログラムから取得するためのAPI。
# 動画情報、チャンネル情報、検索などができる。
#
# 【このアプリでの使用用途】
# - 動画のタイトル、サムネイル取得
# - 動画のメタ情報取得
# - YouTube検索（動画検索機能）
#
# 【API制限について】
# - 1日10,000クォータまで無料
# - 検索1回 = 100クォータ
# - 動画情報取得1回 = 1クォータ
#
# 【APIキーの取得方法】
# 1. Google Cloud Console にアクセス
# 2. プロジェクトを作成
# 3. YouTube Data API v3 を有効化
# 4. 認証情報 → APIキーを作成
# 5. 環境変数 YOUTUBE_API_KEY に設定
#
# 【関連ファイル】
# - app/services/youtube_service.rb: API呼び出しロジック
# - app/controllers/posts_controller.rb: 検索機能
#
require "google/apis/youtube_v3"

# ------------------------------------------
# YouTubeサービスの初期化
# ------------------------------------------
# 【config.youtube_service とは？】
# Railsのアプリケーション設定に独自の値を保存する方法。
# Rails.application.config.youtube_service でアクセス可能。
#
# 【条件分岐の理由】
# APIキーが未設定の場合はnilを返す。
# これにより、APIキーなしでもアプリが起動できる。
# （ただし、YouTube関連機能は使えない）
#
Rails.application.config.youtube_service = if ENV["YOUTUBE_API_KEY"].present?
  # ------------------------------------------
  # APIクライアントの作成
  # ------------------------------------------
  # 【.tap とは？】
  # オブジェクトを作成しつつ、そのオブジェクトに
  # 対して処理を行い、オブジェクト自体を返すメソッド。
  #
  # 以下と同じ意味:
  #   youtube = Google::Apis::YoutubeV3::YouTubeService.new
  #   youtube.key = ENV["YOUTUBE_API_KEY"]
  #   youtube
  #
  Google::Apis::YoutubeV3::YouTubeService.new.tap do |youtube|
    # APIキーを設定
    # これにより認証が完了し、APIを呼び出せるようになる
    youtube.key = ENV["YOUTUBE_API_KEY"]
  end
end
