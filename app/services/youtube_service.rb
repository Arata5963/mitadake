# frozen_string_literal: true

# app/services/youtube_service.rb
# ==========================================
# YouTube API連携サービス
# ==========================================
#
# 【このクラスの役割】
# YouTube Data API v3を使って動画情報を取得する。
# 動画のタイトル、チャンネル名、サムネイル画像などを取得できる。
#
# 【サービスクラスとは？】
# Railsでは「ビジネスロジック」をサービスクラスに切り出すのが一般的。
# モデルやコントローラが肥大化するのを防ぐ。
#
# 【このクラスの構造】
# class << self ... end で全てのメソッドをクラスメソッドとして定義。
# インスタンス化せずに YoutubeService.search_videos(...) のように呼べる。
#
# 【使用例】
#   # 動画を検索
#   YoutubeService.search_videos("Ruby入門")
#   #=> [{ video_id: "xxx", title: "...", ... }, ...]
#
#   # URLから動画情報を取得
#   YoutubeService.fetch_video_info("https://www.youtube.com/watch?v=xxx")
#   #=> { title: "動画タイトル", channel_name: "チャンネル名", ... }
#
# 【依存関係】
# - Google::Apis::YoutubeV3（google-api-client gem）
# - Rails.application.config.youtube_service（初期化済みクライアント）
#
# 【必要な環境変数】
# - YOUTUBE_API_KEY: YouTube Data API v3のAPIキー
#   （Google Cloud Consoleで取得）
#
class YoutubeService
  # ==========================================
  # クラスメソッドの定義ブロック
  # ==========================================
  #
  # 【class << self とは？】
  # このブロック内のメソッドは全て「クラスメソッド」になる。
  # 通常は def self.メソッド名 と書くが、複数ある場合はこの書き方が便利。
  #
  # 【クラスメソッド vs インスタンスメソッド】
  # - クラスメソッド: YoutubeService.search_videos(...)
  #   インスタンス化せずに直接呼べる。
  # - インスタンスメソッド: service = YoutubeService.new; service.search(...)
  #   newしてから呼ぶ。
  #
  class << self
    # ------------------------------------------
    # 動画をタイトルで検索
    # ------------------------------------------
    # 【何をするメソッド？】
    # YouTubeでキーワード検索し、マッチする動画一覧を返す。
    # 動画を新規登録する際の検索機能で使用。
    #
    # 【引数】
    # - query: 検索キーワード（例: "Ruby入門"）
    # - max_results: 最大取得件数（デフォルト10件）
    #
    # 【戻り値】
    # 動画情報のハッシュ配列:
    # [
    #   {
    #     video_id: "dQw4w9WgXcQ",
    #     title: "動画タイトル",
    #     channel_name: "チャンネル名",
    #     thumbnail_url: "https://i.ytimg.com/vi/.../mqdefault.jpg",
    #     youtube_url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
    #   },
    #   ...
    # ]
    #
    # 【処理の流れ】
    # 1. 検索クエリが空なら空配列を返す
    # 2. YouTube APIクライアントを取得
    # 3. YouTube検索APIを呼び出す
    # 4. 結果を整形して返す
    #
    def search_videos(query, max_results: 10)
      # 空のクエリなら何もしない
      return [] if query.blank?

      # Rails設定からYouTube APIクライアントを取得
      # config/initializers/youtube.rb で初期化されている
      youtube = Rails.application.config.youtube_service
      return [] if youtube.nil?

      # YouTube Search APIを呼び出す
      # "snippet" は「基本情報（タイトル、説明など）を取得する」という指定
      response = youtube.list_searches(
        "snippet",          # 取得する情報の種類
        q: query,           # 検索キーワード
        type: "video",      # 動画のみ（チャンネルやプレイリストを除外）
        max_results: max_results,
        order: "relevance"  # 関連度順
      )

      # 検索結果を整形
      # select: 動画IDがあるものだけ抽出（チャンネル等を除外）
      # map: 必要な情報だけを取り出してHashに変換
      response.items
        .select { |item| item.id.video_id.present? }
        .map do |item|
          {
            video_id: item.id.video_id,
            title: item.snippet.title,
            channel_name: item.snippet.channel_title,
            # サムネイル: mediumがあればそれを、なければdefaultを使用
            thumbnail_url: item.snippet.thumbnails.medium&.url || item.snippet.thumbnails.default&.url,
            youtube_url: "https://www.youtube.com/watch?v=#{item.id.video_id}"
          }
        end

    # エラーハンドリング
    # YouTube APIは様々なエラーを返す可能性がある
    rescue Google::Apis::ClientError => e
      # クライアントエラー: 不正なリクエスト、クォータ超過など
      Rails.logger.warn("YouTube API search error: #{e.message}")
      []
    rescue Google::Apis::ServerError => e
      # サーバーエラー: YouTube側の問題
      Rails.logger.error("YouTube API server error: #{e.message}")
      []
    rescue Google::Apis::AuthorizationError => e
      # 認証エラー: APIキーが無効
      Rails.logger.error("YouTube API authorization error: #{e.message}")
      []
    end

    # ------------------------------------------
    # YouTube URLから動画情報を取得
    # ------------------------------------------
    # 【何をするメソッド？】
    # 動画URLを渡すと、その動画のタイトルやチャンネル情報を返す。
    # Post（動画）を保存する前に呼ばれる。
    #
    # 【引数】
    # - youtube_url: YouTube動画のURL
    #   例: "https://www.youtube.com/watch?v=xxx"
    #   例: "https://youtu.be/xxx"
    #
    # 【戻り値】
    # 成功時:
    # {
    #   title: "動画タイトル",
    #   channel_name: "チャンネル名",
    #   channel_id: "UCxxxxxxxx",
    #   channel_thumbnail_url: "https://..."
    # }
    #
    # 失敗時: nil
    #
    def fetch_video_info(youtube_url)
      # URLから動画IDを抽出
      video_id = extract_video_id(youtube_url)
      return nil if video_id.blank?

      # APIから情報を取得
      fetch_from_api(video_id)

    rescue Google::Apis::ClientError => e
      Rails.logger.warn("YouTube API client error: #{e.message}")
      nil
    rescue Google::Apis::ServerError => e
      Rails.logger.error("YouTube API server error: #{e.message}")
      nil
    rescue Google::Apis::AuthorizationError => e
      Rails.logger.error("YouTube API authorization error: #{e.message}")
      nil
    end

    private

    # ==========================================
    # プライベートメソッド
    # ==========================================
    # 【private とは？】
    # これ以降のメソッドはクラス外から呼べなくなる。
    # 内部処理用のヘルパーメソッドを定義する。

    # ------------------------------------------
    # YouTube URLから動画IDを抽出
    # ------------------------------------------
    # 【何をするメソッド？】
    # 様々な形式のYouTube URLから動画IDを取り出す。
    # Post.extract_video_id と同じロジック（重複はあるが依存を避けるため）。
    #
    # 【対応形式】
    # - https://www.youtube.com/watch?v=動画ID
    # - https://youtu.be/動画ID
    #
    # 【処理の解説】
    # URI.parse(url).query で "v=xxx&list=yyy" 部分を取得
    # split("&") で ["v=xxx", "list=yyy"] に分割
    # find { |p| p.start_with?("v=") } で "v=xxx" を見つける
    # delete_prefix("v=") で "xxx" を取得
    #
    def extract_video_id(url)
      return nil if url.blank?

      if url.include?("youtube.com/watch")
        # 通常形式: https://www.youtube.com/watch?v=動画ID
        URI.parse(url).query&.split("&")
           &.find { |p| p.start_with?("v=") }
           &.delete_prefix("v=")
      elsif url.include?("youtu.be/")
        # 短縮形式: https://youtu.be/動画ID
        url.split("youtu.be/").last&.split("?")&.first
      end
    rescue URI::InvalidURIError
      # 不正なURLの場合
      nil
    end

    # ------------------------------------------
    # YouTube Data APIから動画情報を取得
    # ------------------------------------------
    # 【何をするメソッド？】
    # 動画IDを使ってYouTube APIを呼び出し、詳細情報を取得する。
    #
    # 【APIの仕組み】
    # 1. Videos API で動画情報を取得
    # 2. 動画情報からチャンネルIDを取り出す
    # 3. Channels API でチャンネルのサムネイルを取得
    #
    def fetch_from_api(video_id)
      youtube = Rails.application.config.youtube_service
      return nil if youtube.nil?

      # Videos API を呼び出す
      # "snippet" で基本情報（タイトル、チャンネル名など）を取得
      response = youtube.list_videos("snippet", id: video_id)
      return nil if response.items.blank?

      video = response.items.first
      channel_id = video.snippet.channel_id

      # チャンネルのサムネイル画像も取得
      channel_thumbnail_url = fetch_channel_thumbnail(youtube, channel_id)

      # 結果をハッシュで返す
      {
        title: video.snippet.title,
        channel_name: video.snippet.channel_title,
        channel_id: channel_id,
        channel_thumbnail_url: channel_thumbnail_url
      }
    end

    # ------------------------------------------
    # チャンネルのサムネイル画像URLを取得
    # ------------------------------------------
    # 【何をするメソッド？】
    # チャンネルIDからチャンネルのアイコン画像URLを取得する。
    # 動画一覧でチャンネルアイコンを表示するために使用。
    #
    # 【引数】
    # - youtube: YouTube APIクライアント
    # - channel_id: YouTubeチャンネルID（UCxxxxxx形式）
    #
    def fetch_channel_thumbnail(youtube, channel_id)
      return nil if channel_id.blank?

      # Channels API を呼び出す
      response = youtube.list_channels("snippet", id: channel_id)
      return nil if response.items.blank?

      channel = response.items.first

      # サムネイルを取得（defaultかmediumのどちらか）
      # || は「左側がnilなら右側を使う」という意味
      channel.snippet.thumbnails.default&.url ||
        channel.snippet.thumbnails.medium&.url

    rescue StandardError => e
      # チャンネル情報取得に失敗しても、動画情報は返したいのでnilを返す
      Rails.logger.warn("Failed to fetch channel thumbnail: #{e.message}")
      nil
    end
  end
end
