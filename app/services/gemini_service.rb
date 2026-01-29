# frozen_string_literal: true

# Google Gemini API連携サービス（AI機能）
# 動画の字幕やタイトルを分析してアクションプランを自動生成

class GeminiService
  TEXT_TIMEOUT = 60                                            # 生成AIは応答に時間がかかるため長めに設定

  class << self
    # 動画の内容からアクションプランを3つ提案
    def suggest_action_plans(video_id:, title:, description: nil)
      api_key = ENV["GEMINI_API_KEY"]
      return { success: false, error: "Gemini APIキーが設定されていません" } if api_key.blank?
      return { success: false, error: "動画IDがありません" } if video_id.blank?

      transcript_result = TranscriptService.fetch_with_status(video_id)  # 字幕取得を試みる

      prompt = if transcript_result[:success] && transcript_result[:transcript].length >= 100
        build_action_plans_prompt(title, transcript_result[:transcript])  # 字幕ベース（高精度）
      else
        Rails.logger.info("Transcript not available, using title+description for action plans")
        build_action_plans_from_title_prompt(title, description)  # タイトルベース（推測）
      end

      response = call_gemini_with_text(api_key, prompt)
      extract_action_plans(response)

    rescue StandardError => e
      Rails.logger.error("Gemini suggest_action_plans error: #{e.message}")
      { success: false, error: "アクションプランの生成に失敗しました: #{e.message}" }
    end

    # アクションプランをYouTubeタイトル風に変換
    def convert_to_youtube_title(action_plan)
      api_key = ENV["GEMINI_API_KEY"]
      return { success: false, error: "Gemini APIキーが設定されていません" } if api_key.blank?
      return { success: false, error: "アクションプランがありません" } if action_plan.blank?

      prompt = build_youtube_title_prompt(action_plan)
      response = call_gemini_with_text(api_key, prompt)
      extract_youtube_title(response)

    rescue StandardError => e
      Rails.logger.error("Gemini convert_to_youtube_title error: #{e.message}")
      { success: false, error: "変換に失敗しました: #{e.message}" }
    end

    private

    # Gemini APIにプロンプトを送信
    def call_gemini_with_text(api_key, prompt)
      uri = URI("https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=#{api_key}")
      request_body = { contents: [ { parts: [ { text: prompt } ] } ] }

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true                                      # HTTPS必須
      http.read_timeout = TEXT_TIMEOUT

      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"
      request.body = request_body.to_json

      response = http.request(request)
      JSON.parse(response.body)
    end

    # アクションプラン提案用プロンプト（字幕ベース）
    def build_action_plans_prompt(title, transcript)
      max_chars = 30_000                                       # API制限対策
      truncated = transcript.length > max_chars ? transcript[0, max_chars] + "\n\n（字幕が長いため一部省略）" : transcript

      <<~PROMPT
        以下はYouTube動画「#{title}」の字幕テキストです。
        この動画を見た視聴者が「今日すぐに」実行できる単発アクションを3個、YouTubeの動画タイトル風に提案してください。

        【字幕テキスト】
        #{truncated}

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

    # アクションプラン提案用プロンプト（タイトルベース）
    def build_action_plans_from_title_prompt(title, description)
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

    # アクションプランのレスポンスをパース
    def extract_action_plans(response)
      if response["error"]
        error_message = response.dig("error", "message") || "APIエラーが発生しました"
        Rails.logger.error("Gemini API error response: #{error_message}")
        if error_message.include?("429") || error_message.include?("quota") || error_message.include?("rate")
          return { success: false, error: "AIが混み合っています。約20秒後に再試行してください。", error_type: "rate_limit" }
        end
        return { success: false, error: "アクションプランの生成に失敗しました" }
      end

      text = response.dig("candidates", 0, "content", "parts", 0, "text")  # ネストしたHashから安全に取得
      return { success: false, error: "アクションプランを生成できませんでした" } if text.blank?

      json_match = text.match(/\{[\s\S]*\}/m)                  # JSON部分を抽出
      unless json_match
        Rails.logger.error("Failed to extract JSON from action plans response: #{text}")
        return { success: false, error: "アクションプランの解析に失敗しました" }
      end

      begin
        data = JSON.parse(json_match[0])
        action_plans = data["action_plans"]
        unless action_plans.is_a?(Array) && action_plans.length > 0
          return { success: false, error: "アクションプランが見つかりませんでした" }
        end
        action_plans = action_plans.first(3)                   # 最大3個に制限
        { success: true, action_plans: action_plans }
      rescue JSON::ParserError => e
        Rails.logger.error("JSON parse error in action plans: #{e.message}")
        { success: false, error: "アクションプランの解析に失敗しました" }
      end
    end

    # YouTubeタイトル風変換用プロンプト
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

    # YouTubeタイトル変換レスポンスをパース
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
      return { success: false, error: "タイトルを生成できませんでした" } if text.blank?

      json_match = text.match(/\{[\s\S]*\}/m)
      unless json_match
        Rails.logger.error("Failed to extract JSON from youtube title response: #{text}")
        return { success: false, error: "タイトルの解析に失敗しました" }
      end

      begin
        data = JSON.parse(json_match[0])
        title = data["title"]
        return { success: false, error: "タイトルが見つかりませんでした" } if title.blank?
        { success: true, title: title }
      rescue JSON::ParserError => e
        Rails.logger.error("JSON parse error in youtube title: #{e.message}")
        { success: false, error: "タイトルの解析に失敗しました" }
      end
    end
  end
end
