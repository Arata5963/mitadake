# frozen_string_literal: true

# app/services/gemini_service.rb
# ==========================================
# Google Gemini API連携サービス（AI機能）
# ==========================================
#
# 【このクラスの役割】
# Google Gemini（生成AI）を使ってアクションプランを自動生成する。
# YouTube動画の字幕やタイトルを分析して、視聴者が実行できるアクションを提案。
#
# 【主な機能】
# 1. suggest_action_plans: 動画から3つのアクションプランを提案
# 2. convert_to_youtube_title: プランをYouTubeタイトル風に変換
#
# 【処理の流れ】
#
#   動画URL → 字幕取得 → Gemini API → アクションプラン3つ
#            ↓
#         字幕がない場合
#            ↓
#         タイトルから推測 → Gemini API → アクションプラン3つ
#
# 【Gemini APIとは？】
# Googleが提供する生成AIサービス。
# テキストを入力すると、AIが適切な回答を生成して返す。
# ChatGPTのGoogle版のようなもの。
#
# 【必要な環境変数】
# - GEMINI_API_KEY: Gemini APIキー（Google AI Studioで取得）
#
# 【依存関係】
# - TranscriptService（字幕取得用）
# - Net::HTTP（HTTP通信用、Ruby標準ライブラリ）
#
class GeminiService

  # APIタイムアウト設定（秒）
  # 生成AIは応答に時間がかかることがあるため、60秒と長めに設定
  TEXT_TIMEOUT = 60

  # ==========================================
  # クラスメソッドの定義ブロック
  # ==========================================
  class << self

    # ------------------------------------------
    # アクションプランの提案を生成
    # ------------------------------------------
    # 【何をするメソッド？】
    # YouTube動画の内容を分析して、視聴者が「今日すぐに」
    # 実行できるアクションプランを3つ提案する。
    #
    # 【引数】
    # - video_id: YouTube動画ID（例: "dQw4w9WgXcQ"）
    # - title: 動画のタイトル
    # - description: 動画の説明文（オプション）
    #
    # 【戻り値】
    # 成功時:
    # {
    #   success: true,
    #   action_plans: [
    #     "【やってみた】朝5時起きを実践した結果",
    #     "【検証】読書メモをNotionに記録してみた",
    #     "【実践】部屋の断捨離に挑戦してみた"
    #   ]
    # }
    #
    # 失敗時:
    # { success: false, error: "エラーメッセージ" }
    #
    # 【処理の流れ】
    # 1. APIキーと動画IDのチェック
    # 2. TranscriptServiceで字幕を取得
    # 3. 字幕があれば字幕ベースでプロンプト作成
    #    なければタイトル＋説明文からプロンプト作成
    # 4. Gemini APIを呼び出し
    # 5. レスポンスからアクションプランを抽出
    #
    def suggest_action_plans(video_id:, title:, description: nil)
      # APIキーの存在チェック
      api_key = ENV["GEMINI_API_KEY"]
      return { success: false, error: "Gemini APIキーが設定されていません" } if api_key.blank?
      return { success: false, error: "動画IDがありません" } if video_id.blank?

      # 1. 字幕取得を試みる
      transcript_result = TranscriptService.fetch_with_status(video_id)

      # 2. プロンプト（AIへの指示文）を作成
      if transcript_result[:success] && transcript_result[:transcript].length >= 100
        # 字幕が取得できた場合: 字幕を使って精度の高い提案
        prompt = build_action_plans_prompt(title, transcript_result[:transcript])
      else
        # 字幕がない場合: タイトルと説明文から推測
        Rails.logger.info("Transcript not available, using title+description for action plans")
        prompt = build_action_plans_from_title_prompt(title, description)
      end

      # 3. Gemini APIを呼び出し
      response = call_gemini_with_text(api_key, prompt)

      # 4. レスポンスをパースしてアクションプランを抽出
      extract_action_plans(response)

    rescue StandardError => e
      Rails.logger.error("Gemini suggest_action_plans error: #{e.message}")
      { success: false, error: "アクションプランの生成に失敗しました: #{e.message}" }
    end

    # ------------------------------------------
    # アクションプランをYouTubeタイトル風に変換
    # ------------------------------------------
    # 【何をするメソッド？】
    # ユーザーが入力したシンプルなアクションプランを、
    # 「やってみた」系のキャッチーなタイトルに変換する。
    #
    # 【使用例】
    # 入力: "読書メモをNotionに記録する"
    # 出力: "【やってみた】読書メモをNotionに記録した結果"
    #
    # 【引数】
    # - action_plan: 元のアクションプラン（例: "朝5時に起きる"）
    #
    # 【戻り値】
    # 成功時: { success: true, title: "変換後のタイトル" }
    # 失敗時: { success: false, error: "エラーメッセージ" }
    #
    def convert_to_youtube_title(action_plan)
      api_key = ENV["GEMINI_API_KEY"]
      return { success: false, error: "Gemini APIキーが設定されていません" } if api_key.blank?
      return { success: false, error: "アクションプランがありません" } if action_plan.blank?

      # プロンプトを作成してAPIを呼び出す
      prompt = build_youtube_title_prompt(action_plan)
      response = call_gemini_with_text(api_key, prompt)
      extract_youtube_title(response)

    rescue StandardError => e
      Rails.logger.error("Gemini convert_to_youtube_title error: #{e.message}")
      { success: false, error: "変換に失敗しました: #{e.message}" }
    end

    private

    # ==========================================
    # プライベートメソッド
    # ==========================================

    # ------------------------------------------
    # Gemini APIを呼び出す（共通処理）
    # ------------------------------------------
    # 【何をするメソッド？】
    # Gemini APIにプロンプトを送信し、AIの回答を取得する。
    #
    # 【処理の流れ】
    # 1. APIのURLを組み立てる
    # 2. リクエストボディをJSON形式で作成
    # 3. HTTPS接続を確立
    # 4. POSTリクエストを送信
    # 5. レスポンスをJSONとしてパース
    #
    # 【Net::HTTP とは？】
    # Ruby標準ライブラリのHTTPクライアント。
    # 外部APIとの通信に使用する。
    #
    def call_gemini_with_text(api_key, prompt)
      # APIエンドポイントURL
      # gemini-2.5-flash は高速・低コストなモデル
      uri = URI("https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=#{api_key}")

      # リクエストボディ（Gemini APIの形式に従う）
      # contents > parts > text にプロンプトを入れる
      request_body = {
        contents: [
          {
            parts: [
              { text: prompt }
            ]
          }
        ]
      }

      # HTTPS接続を確立
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true  # HTTPSを使用
      http.read_timeout = TEXT_TIMEOUT  # タイムアウト設定

      # POSTリクエストを作成
      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"
      request.body = request_body.to_json  # ハッシュをJSON文字列に変換

      # リクエスト送信してレスポンスを受け取る
      response = http.request(request)

      # レスポンスボディをJSONとしてパース
      JSON.parse(response.body)
    end

    # ------------------------------------------
    # アクションプラン提案用プロンプト（字幕ベース）
    # ------------------------------------------
    # 【何をするメソッド？】
    # 動画の字幕テキストを使って、Geminiに送るプロンプトを作成する。
    # 字幕があると、動画の内容を正確に理解できるので精度が高い。
    #
    # 【プロンプトエンジニアリングのポイント】
    # 1. 明確な役割を与える
    # 2. 具体的な出力形式を指定（JSON）
    # 3. 良い例・悪い例を示す
    # 4. 制約を明示する
    #
    def build_action_plans_prompt(title, transcript)
      # 字幕が長すぎる場合は省略（APIの制限対策）
      max_chars = 30_000
      truncated_transcript = if transcript.length > max_chars
                                transcript[0, max_chars] + "\n\n（字幕が長いため一部省略）"
                              else
                                transcript
                              end

      # ヒアドキュメント（複数行の文字列を書く方法）
      # <<~PROMPT で始まり、PROMPT で終わる
      # ~ があると行頭のインデントが自動で除去される
      <<~PROMPT
        以下はYouTube動画「#{title}」の字幕テキストです。
        この動画を見た視聴者が「今日すぐに」実行できる単発アクションを3個、YouTubeの動画タイトル風に提案してください。

        【字幕テキスト】
        #{truncated_transcript}

        【回答形式】
        以下のJSON形式で回答してください。JSONのみを返し、他のテキストは含めないでください。

        {
          "action_plans": [
            "【やってみた】〇〇した結果",
            "【検証】〇〇してみた",
            "【実践】〇〇に挑戦してみた"
          ]
        }

        【重要な作成ルール】
        - 必ず3個のアクションを提案してください
        - YouTubeの動画タイトル風に書いてください（【】を使う、「〜してみた」「〜した結果」など）
        - 「1回で完了する」単発アクションのみ（習慣化や継続的な取り組みはNG）
        - 過去形で書いてください（やってみた、した結果、など）
        - 30文字以内に収めてください
        - 動画の内容に直接関連したアクションのみを提案してください

        【良い例】
        - 「【やってみた】朝5時起きを実践した結果」
        - 「【検証】読書メモをNotionに記録してみた」
        - 「【実践】部屋の断捨離に挑戦してみた」
        - 「10分間瞑想してみた結果がヤバい」

        【悪い例（これらは提案しないこと）】
        - 「毎日〇〇する」（習慣化はNG）
        - 「〇〇を継続する」（継続はNG）
        - 「〇〇をする」（現在形はNG、過去形にする）
      PROMPT
    end

    # ------------------------------------------
    # アクションプラン提案用プロンプト（タイトルベース）
    # ------------------------------------------
    # 【何をするメソッド？】
    # 字幕が取得できない場合に、タイトルと説明文だけで
    # プロンプトを作成する。字幕ベースより精度は落ちる。
    #
    def build_action_plans_from_title_prompt(title, description)
      # 説明文があれば追加（1000文字で切り捨て）
      # truncate はRailsのメソッドで、指定文字数で切り捨てる
      desc_text = description.present? ? "\n動画の説明: #{description.truncate(1000)}" : ""

      <<~PROMPT
        以下のYouTube動画について、視聴者が「今日すぐに」実行できる単発アクションを3個、YouTubeの動画タイトル風に提案してください。

        動画タイトル: #{title}#{desc_text}

        【回答形式】
        以下のJSON形式で回答してください。JSONのみを返し、他のテキストは含めないでください。

        {
          "action_plans": [
            "【やってみた】〇〇した結果",
            "【検証】〇〇してみた",
            "【実践】〇〇に挑戦してみた"
          ]
        }

        【重要な作成ルール】
        - 必ず3個のアクションを提案してください
        - YouTubeの動画タイトル風に書いてください（【】を使う、「〜してみた」「〜した結果」など）
        - タイトルから推測される動画内容に基づいて提案してください
        - 「1回で完了する」単発アクションのみ（習慣化や継続的な取り組みはNG）
        - 過去形で書いてください（やってみた、した結果、など）
        - 30文字以内に収めてください

        【良い例】
        - 「【やってみた】朝5時起きを実践した結果」
        - 「【検証】読書メモをNotionに記録してみた」
        - 「【実践】部屋の断捨離に挑戦してみた」
        - 「10分間瞑想してみた結果がヤバい」

        【悪い例（これらは提案しないこと）】
        - 「毎日〇〇する」（習慣化はNG）
        - 「〇〇を継続する」（継続はNG）
        - 「〇〇をする」（現在形はNG、過去形にする）
      PROMPT
    end

    # ------------------------------------------
    # アクションプランのレスポンスをパース
    # ------------------------------------------
    # 【何をするメソッド？】
    # Gemini APIのレスポンスから、アクションプラン配列を取り出す。
    #
    # 【レスポンスの構造】
    # {
    #   "candidates": [
    #     {
    #       "content": {
    #         "parts": [
    #           { "text": "{\"action_plans\": [...]}" }
    #         ]
    #       }
    #     }
    #   ]
    # }
    #
    # 【dig とは？】
    # ネストしたハッシュ/配列から値を安全に取得するメソッド。
    # response.dig("candidates", 0, "content", "parts", 0, "text")
    # は以下と同じ:
    # response["candidates"][0]["content"]["parts"][0]["text"]
    # ただし、途中でnilがあってもエラーにならずnilを返す。
    #
    def extract_action_plans(response)
      # エラーレスポンスのチェック
      if response["error"]
        error_message = response.dig("error", "message") || "APIエラーが発生しました"
        Rails.logger.error("Gemini API error response: #{error_message}")

        # レート制限エラーを検出（429はHTTPステータス「Too Many Requests」）
        if error_message.include?("429") || error_message.include?("quota") || error_message.include?("rate")
          return { success: false, error: "AIが混み合っています。約20秒後に再試行してください。", error_type: "rate_limit" }
        end

        return { success: false, error: "アクションプランの生成に失敗しました" }
      end

      # AIの回答テキストを取り出す
      text = response.dig("candidates", 0, "content", "parts", 0, "text")

      if text.blank?
        return { success: false, error: "アクションプランを生成できませんでした" }
      end

      # JSON部分を抽出
      # AIの回答には余計なテキストが含まれることがあるため、
      # 正規表現で {...} の部分だけを取り出す
      json_match = text.match(/\{[\s\S]*\}/m)
      unless json_match
        Rails.logger.error("Failed to extract JSON from action plans response: #{text}")
        return { success: false, error: "アクションプランの解析に失敗しました" }
      end

      begin
        # JSONをパースしてRubyのハッシュに変換
        data = JSON.parse(json_match[0])
        action_plans = data["action_plans"]

        # action_plans が配列で、要素があることを確認
        unless action_plans.is_a?(Array) && action_plans.length > 0
          return { success: false, error: "アクションプランが見つかりませんでした" }
        end

        # 最大3個に制限（AIが4個以上返すことがあるため）
        action_plans = action_plans.first(3)

        { success: true, action_plans: action_plans }

      rescue JSON::ParserError => e
        Rails.logger.error("JSON parse error in action plans: #{e.message}")
        { success: false, error: "アクションプランの解析に失敗しました" }
      end
    end

    # ------------------------------------------
    # YouTubeタイトル風変換用プロンプト
    # ------------------------------------------
    # 【何をするメソッド？】
    # アクションプランをYouTubeタイトル風に変換するための
    # プロンプトを作成する。
    #
    def build_youtube_title_prompt(action_plan)
      <<~PROMPT
        あなたはYouTubeタイトルのエキスパートです。
        以下のアクションプランを、YouTubeの動画タイトル風に変換してください。

        【元のアクションプラン】
        #{action_plan}

        【回答形式】
        以下のJSON形式で回答してください。JSONのみを返し、他のテキストは含めないでください。

        {
          "title": "変換後のタイトル"
        }

        【変換ルール】
        - 1回で完了するワンアクションを「やってみた」系のタイトルにする
        - 【】や「」を使ってキャッチーにする
        - 結果が気になる形にする
        - 30文字以内に収める
        - 過去形で書く（やってみた、した結果、など）

        【変換例】
        - 「読書メモをNotionに記録する」→「【やってみた】読書メモをNotionに記録した結果」
        - 「朝5時に起きる」→「【検証】朝5時起きを実践してみた」
        - 「1日水を2リットル飲む」→「1日2L水を飲んでみた結果がヤバい」
        - 「部屋を断捨離する」→「【Before/After】部屋を断捨離してみた」
        - 「コーヒーを1週間やめる」→「コーヒーやめてみた結果…」
      PROMPT
    end

    # ------------------------------------------
    # YouTubeタイトル変換レスポンスをパース
    # ------------------------------------------
    # 【何をするメソッド？】
    # Gemini APIのレスポンスから、変換後のタイトルを取り出す。
    # extract_action_plans と似た処理だが、
    # 返すのは配列ではなく単一のタイトル文字列。
    #
    def extract_youtube_title(response)
      if response["error"]
        error_message = response.dig("error", "message") || "APIエラーが発生しました"
        Rails.logger.error("Gemini API error response: #{error_message}")

        if error_message.include?("429") || error_message.include?("quota") || error_message.include?("rate")
          return { success: false, error: "AIが混み合っています。少し待ってから再試行してください。" }
        end

        return { success: false, error: "変換に失敗しました: #{error_message}" }
      end

      text = response.dig("candidates", 0, "content", "parts", 0, "text")

      if text.blank?
        return { success: false, error: "タイトルを生成できませんでした" }
      end

      # JSON部分を抽出
      json_match = text.match(/\{[\s\S]*\}/m)
      unless json_match
        Rails.logger.error("Failed to extract JSON from youtube title response: #{text}")
        return { success: false, error: "タイトルの解析に失敗しました" }
      end

      begin
        data = JSON.parse(json_match[0])
        title = data["title"]

        if title.blank?
          return { success: false, error: "タイトルが見つかりませんでした" }
        end

        { success: true, title: title }

      rescue JSON::ParserError => e
        Rails.logger.error("JSON parse error in youtube title: #{e.message}")
        { success: false, error: "タイトルの解析に失敗しました" }
      end
    end
  end
end
