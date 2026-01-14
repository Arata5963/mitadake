# frozen_string_literal: true

# Gemini APIを使用してYouTube動画の学習ガイドを生成するサービスクラス
class GeminiService
  TEXT_TIMEOUT = 60 # テキスト分析用タイムアウト

  class << self
    # クイズ問題を生成
    # @param video_id [String] YouTube動画ID
    # @param title [String] 動画タイトル（オプション）
    # @return [Hash] { success: true, questions: [...] } または { success: false, error: "エラーメッセージ" }
    def generate_quiz(video_id:, title: nil)
      api_key = ENV["GEMINI_API_KEY"]
      return { success: false, error: "Gemini APIキーが設定されていません" } if api_key.blank?
      return { success: false, error: "動画IDがありません" } if video_id.blank?

      # 字幕を取得
      transcript_result = TranscriptService.fetch_with_status(video_id)
      unless transcript_result[:success]
        return { success: false, error: transcript_result[:error] }
      end

      transcript = transcript_result[:transcript]
      if transcript.length < 100
        return { success: false, error: "字幕が短すぎます" }
      end

      # クイズ生成用プロンプトを構築
      prompt = build_quiz_prompt(title || "YouTube動画", transcript)
      response = call_gemini_with_text(api_key, prompt)
      extract_quiz_questions(response)
    rescue StandardError => e
      Rails.logger.error("Gemini generate_quiz error: #{e.message}")
      { success: false, error: "クイズの生成に失敗しました: #{e.message}" }
    end

    # 動画から引用候補を抽出（選択式UI用）
    # @param video_id [String] YouTube動画ID
    # @param title [String] 動画タイトル（オプション）
    # @return [Hash] { success: true, quotes: [...] } または { success: false, error: "エラーメッセージ" }
    def suggest_quotes(video_id:, title: nil)
      api_key = ENV["GEMINI_API_KEY"]
      return { success: false, error: "Gemini APIキーが設定されていません" } if api_key.blank?
      return { success: false, error: "動画IDがありません" } if video_id.blank?

      # 字幕を取得
      transcript_result = TranscriptService.fetch_with_status(video_id)
      unless transcript_result[:success]
        return { success: false, error: transcript_result[:error] }
      end

      transcript = transcript_result[:transcript]
      if transcript.length < 100
        return { success: false, error: "字幕が短すぎます" }
      end

      # 引用抽出用プロンプト
      prompt = build_suggest_quotes_prompt(title || "YouTube動画", transcript)
      response = call_gemini_with_text(api_key, prompt)
      extract_suggested_quotes(response)
    rescue StandardError => e
      Rails.logger.error("Gemini suggest_quotes error: #{e.message}")
      { success: false, error: "引用の抽出に失敗しました: #{e.message}" }
    end

    # アクションプランの提案を生成（3個）
    # @param video_id [String] YouTube動画ID
    # @param title [String] 動画タイトル
    # @param description [String] 動画説明文（オプション）
    # @return [Hash] { success: true, action_plans: [...] } または { success: false, error: "エラーメッセージ" }
    def suggest_action_plans(video_id:, title:, description: nil)
      api_key = ENV["GEMINI_API_KEY"]
      return { success: false, error: "Gemini APIキーが設定されていません" } if api_key.blank?
      return { success: false, error: "動画IDがありません" } if video_id.blank?

      # 1. 字幕ベースで生成を試行
      transcript_result = TranscriptService.fetch_with_status(video_id)

      if transcript_result[:success] && transcript_result[:transcript].length >= 100
        # 字幕から生成
        prompt = build_action_plans_prompt(title, transcript_result[:transcript])
      else
        # 2. 字幕がない場合はタイトル＋説明文から生成
        Rails.logger.info("Transcript not available, using title+description for action plans")
        prompt = build_action_plans_from_title_prompt(title, description)
      end

      response = call_gemini_with_text(api_key, prompt)
      extract_action_plans(response)
    rescue StandardError => e
      Rails.logger.error("Gemini suggest_action_plans error: #{e.message}")
      { success: false, error: "アクションプランの生成に失敗しました: #{e.message}" }
    end

    # エントリータイプに応じたコンテンツを生成
    # @param video_id [String] YouTube動画ID
    # @param entry_type [String] "keyPoint", "quote", "action"
    # @param title [String] 動画タイトル（オプション）
    # @return [Hash] { success: true, content: "テキスト" } または { success: false, error: "エラーメッセージ" }
    def generate_entry(video_id:, entry_type:, title: nil)
      api_key = ENV["GEMINI_API_KEY"]
      return { success: false, error: "Gemini APIキーが設定されていません" } if api_key.blank?
      return { success: false, error: "動画IDがありません" } if video_id.blank?

      # 字幕を取得
      transcript_result = TranscriptService.fetch_with_status(video_id)
      unless transcript_result[:success]
        return { success: false, error: transcript_result[:error] }
      end

      transcript = transcript_result[:transcript]
      if transcript.length < 100
        return { success: false, error: "字幕が短すぎます" }
      end

      # タイプに応じたプロンプトを構築
      prompt = build_entry_prompt(entry_type, title || "YouTube動画", transcript)
      response = call_gemini_with_text(api_key, prompt)
      extract_content(response)
    rescue StandardError => e
      Rails.logger.error("Gemini generate_entry error: #{e.message}")
      { success: false, error: "生成に失敗しました: #{e.message}" }
    end

    # YouTubeコメントを4カテゴリに分類
    # @param comments [Array<Hash>] コメント配列 [{ comment_id:, text:, ... }, ...]
    # @param video_title [String] 動画タイトル（コンテキスト用）
    # @return [Hash] { success: true, categorized_comments: [...] } または { success: false, error: "エラーメッセージ" }
    def categorize_comments(comments:, video_title: nil)
      api_key = ENV["GEMINI_API_KEY"]
      return { success: false, error: "Gemini APIキーが設定されていません" } if api_key.blank?
      return { success: false, error: "コメントがありません" } if comments.blank?

      # コメントをナンバリングしてプロンプトに含める
      prompt = build_categorize_comments_prompt(comments, video_title)
      response = call_gemini_with_text(api_key, prompt)
      extract_categorized_comments(response, comments)
    rescue StandardError => e
      Rails.logger.error("Gemini categorize_comments error: #{e.message}")
      { success: false, error: "コメント分類に失敗しました: #{e.message}" }
    end

    # YouTube動画の学習ガイドを生成
    # 優先順位: 1. 字幕ベース → 2. タイトルベース
    # @param post [Post] 投稿オブジェクト
    # @return [Hash] { success: true, summary: "テキスト" } または { success: false, error: "エラーメッセージ" }
    def summarize_video(post)
      return { success: false, error: "投稿情報がありません" } if post.nil?

      api_key = ENV["GEMINI_API_KEY"]
      return { success: false, error: "Gemini APIキーが設定されていません" } if api_key.blank?

      video_id = post.youtube_video_id
      return { success: false, error: "動画IDがありません" } if video_id.blank?

      # 1. 字幕ベース分析を試行（高速・高精度）
      result = try_transcript_analysis(api_key, video_id, post)
      return result if result[:success]

      # 2. 字幕取得失敗時はタイトルベースにフォールバック
      Rails.logger.info("Transcript analysis failed, falling back to title-based analysis")
      try_title_analysis(api_key, post)
    rescue StandardError => e
      Rails.logger.error("Gemini API error: #{e.message}")
      { success: false, error: "要約の生成に失敗しました: #{e.message}" }
    end

    private

    # 字幕ベース分析を試行
    def try_transcript_analysis(api_key, video_id, post)
      # 字幕を取得
      transcript_result = TranscriptService.fetch_with_status(video_id)

      unless transcript_result[:success]
        Rails.logger.info("Transcript not available: #{transcript_result[:error]}")
        return { success: false, error: transcript_result[:error] }
      end

      transcript = transcript_result[:transcript]

      # 字幕が短すぎる場合はスキップ
      if transcript.length < 100
        Rails.logger.info("Transcript too short: #{transcript.length} chars")
        return { success: false, error: "字幕が短すぎます" }
      end

      # 字幕をGeminiに渡して分析
      title = post.youtube_title.presence || "YouTube動画"
      prompt = build_transcript_prompt(title, transcript)

      response = call_gemini_with_text(api_key, prompt)
      extract_summary(response)
    rescue StandardError => e
      Rails.logger.warn("Transcript analysis failed: #{e.message}")
      { success: false, error: e.message }
    end

    # タイトルベース分析（フォールバック）
    def try_title_analysis(api_key, post)
      title = post.youtube_title.presence || "YouTube動画"
      channel = post.youtube_channel_name
      prompt = build_title_prompt(title, channel)

      response = call_gemini_with_text(api_key, prompt)
      result = extract_summary(response)

      # フォールバックであることを示すメッセージを追加
      if result[:success]
        result[:summary] = "※ 字幕を取得できなかったため、タイトルに基づいて生成しました\n\n" + result[:summary]
      end
      result
    rescue StandardError => e
      Rails.logger.error("Title analysis failed: #{e.message}")
      { success: false, error: "要約の生成に失敗しました" }
    end

    # Gemini APIにテキストを渡してコンテンツ生成
    def call_gemini_with_text(api_key, prompt)
      uri = URI("https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=#{api_key}")

      request_body = {
        contents: [
          {
            parts: [
              { text: prompt }
            ]
          }
        ]
      }

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = TEXT_TIMEOUT

      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"
      request.body = request_body.to_json

      response = http.request(request)
      JSON.parse(response.body)
    end

    # クイズ生成用プロンプト
    def build_quiz_prompt(title, transcript)
      max_chars = 30_000
      truncated_transcript = if transcript.length > max_chars
                                transcript[0, max_chars] + "\n\n（字幕が長いため一部省略）"
                              else
                                transcript
                              end

      <<~PROMPT
        以下はYouTube動画「#{title}」の字幕テキストです。
        この動画の内容理解度をチェックするクイズを5問作成してください。

        【字幕テキスト】
        #{truncated_transcript}

        【回答形式】
        以下のJSON形式で回答してください。JSONのみを返し、他のテキストは含めないでください。

        {
          "questions": [
            {
              "question_text": "問題文",
              "option_1": "選択肢1",
              "option_2": "選択肢2",
              "option_3": "選択肢3",
              "option_4": "選択肢4",
              "correct_option": 1
            }
          ]
        }

        【作成ルール】
        - 問題は5問作成してください
        - 各問題は4択形式です
        - correct_option は正解の選択肢番号（1〜4）を指定してください
        - 動画の内容に基づいた問題を作成してください
        - 問題の難易度は中程度にしてください（簡単すぎず、難しすぎず）
        - 問題文は質問形式で記載してください
        - 選択肢は明確に区別できるものにしてください
      PROMPT
    end

    # クイズJSONレスポンスをパース
    def extract_quiz_questions(response)
      if response["error"]
        error_message = response.dig("error", "message") || "APIエラーが発生しました"
        Rails.logger.error("Gemini API error response: #{error_message}")

        if error_message.include?("429") || error_message.include?("quota")
          return { success: false, error: "APIリクエスト制限に達しました。しばらく待ってから再試行してください。" }
        end

        return { success: false, error: "クイズの生成に失敗しました: #{error_message}" }
      end

      text = response.dig("candidates", 0, "content", "parts", 0, "text")

      if text.blank?
        return { success: false, error: "クイズを生成できませんでした" }
      end

      # JSONを抽出してパース
      json_match = text.match(/\{[\s\S]*\}/m)
      unless json_match
        Rails.logger.error("Failed to extract JSON from response: #{text}")
        return { success: false, error: "クイズデータの解析に失敗しました" }
      end

      begin
        quiz_data = JSON.parse(json_match[0])
        questions = quiz_data["questions"]

        unless questions.is_a?(Array) && questions.length == 5
          return { success: false, error: "クイズの問題数が正しくありません" }
        end

        # 各問題のバリデーション
        questions.each_with_index do |q, i|
          unless q["question_text"].present? &&
                 q["option_1"].present? && q["option_2"].present? &&
                 q["option_3"].present? && q["option_4"].present? &&
                 q["correct_option"].to_i.between?(1, 4)
            return { success: false, error: "問題#{i + 1}のデータが不正です" }
          end
        end

        { success: true, questions: questions }
      rescue JSON::ParserError => e
        Rails.logger.error("JSON parse error: #{e.message}")
        { success: false, error: "クイズデータの解析に失敗しました" }
      end
    end

    # エントリータイプ別プロンプトを構築
    def build_entry_prompt(entry_type, title, transcript)
      max_chars = 30_000
      truncated_transcript = if transcript.length > max_chars
                                transcript[0, max_chars] + "\n\n（字幕が長いため一部省略）"
                              else
                                transcript
                              end

      case entry_type
      when "keyPoint"
        build_key_point_prompt(title, truncated_transcript)
      when "quote"
        build_quote_prompt(title, truncated_transcript)
      when "action"
        build_action_prompt(title, truncated_transcript)
      else
        build_key_point_prompt(title, truncated_transcript)
      end
    end

    # 要約用プロンプト
    def build_key_point_prompt(title, transcript)
      <<~PROMPT
        以下はYouTube動画「#{title}」の字幕テキストです。
        この動画の内容を要約してください。

        【字幕テキスト】
        #{transcript}

        【回答形式】
        - 動画の主なテーマを1文で説明
        - 重要なポイントを3〜5個、箇条書きで簡潔に

        ※ マークダウン形式ではなく、プレーンテキストで回答してください。
        ※ 見出し（#や##）は使わないでください。
      PROMPT
    end

    # 引用抽出用プロンプト
    def build_quote_prompt(title, transcript)
      <<~PROMPT
        以下はYouTube動画「#{title}」の字幕テキストです。
        この動画から印象的で引用に値する発言を3〜5個抽出してください。

        【字幕テキスト】
        #{transcript}

        【回答形式】
        各引用は「」で囲んで、1行に1つずつ記載してください。

        例:
        「成功の秘訣は、毎日少しずつ続けること」
        「失敗を恐れるな、失敗から学べ」

        ※ 動画内で実際に述べられた言葉のみを抽出してください。
        ※ 創作や要約ではなく、原文に近い形で引用してください。
      PROMPT
    end

    # 引用候補抽出用プロンプト（選択式UI用）
    def build_suggest_quotes_prompt(title, transcript)
      max_chars = 30_000
      truncated_transcript = if transcript.length > max_chars
                                transcript[0, max_chars] + "\n\n（字幕が長いため一部省略）"
                              else
                                transcript
                              end

      <<~PROMPT
        以下はYouTube動画「#{title}」の字幕テキストです。
        この動画から心に残る名言・印象的な発言を5〜8個抽出してください。

        【字幕テキスト】
        #{truncated_transcript}

        【回答形式】
        以下のJSON形式で回答してください。JSONのみを返し、他のテキストは含めないでください。

        {
          "quotes": [
            "名言1",
            "名言2",
            "名言3"
          ]
        }

        【抽出ルール】
        - 動画内で実際に述べられた言葉のみを抽出してください
        - 1つの引用は1〜2文程度の長さにしてください
        - 感動的、教訓的、ユニークな発言を優先してください
        - 創作や要約ではなく、原文に近い形で抽出してください
      PROMPT
    end

    # 引用候補のJSONレスポンスをパース
    def extract_suggested_quotes(response)
      if response["error"]
        error_message = response.dig("error", "message") || "APIエラーが発生しました"
        Rails.logger.error("Gemini API error response: #{error_message}")
        return { success: false, error: "引用の抽出に失敗しました: #{error_message}" }
      end

      text = response.dig("candidates", 0, "content", "parts", 0, "text")

      if text.blank?
        return { success: false, error: "引用を抽出できませんでした" }
      end

      # JSONを抽出してパース
      json_match = text.match(/\{[\s\S]*\}/m)
      unless json_match
        Rails.logger.error("Failed to extract JSON from response: #{text}")
        return { success: false, error: "引用データの解析に失敗しました" }
      end

      begin
        data = JSON.parse(json_match[0])
        quotes = data["quotes"]

        unless quotes.is_a?(Array) && quotes.length > 0
          return { success: false, error: "引用が見つかりませんでした" }
        end

        { success: true, quotes: quotes }
      rescue JSON::ParserError => e
        Rails.logger.error("JSON parse error: #{e.message}")
        { success: false, error: "引用データの解析に失敗しました" }
      end
    end

    # アクションプラン提案用プロンプト（字幕ベース）
    def build_action_plans_prompt(title, transcript)
      max_chars = 30_000
      truncated_transcript = if transcript.length > max_chars
                                transcript[0, max_chars] + "\n\n（字幕が長いため一部省略）"
                              else
                                transcript
                              end

      <<~PROMPT
        以下はYouTube動画「#{title}」の字幕テキストです。
        この動画を見た視聴者が「今日すぐに」実行できる単発アクションを3個提案してください。

        【字幕テキスト】
        #{truncated_transcript}

        【回答形式】
        以下のJSON形式で回答してください。JSONのみを返し、他のテキストは含めないでください。

        {
          "action_plans": [
            "アクション1",
            "アクション2",
            "アクション3"
          ]
        }

        【重要な作成ルール】
        - 必ず3個のアクションを提案してください
        - 「1回で完了する」単発アクションのみ（習慣化や継続的な取り組みはNG）
        - 「今日」「今すぐ」「今週末に」など、すぐに実行できる内容
        - 「〜する」という形式で、短く簡潔に記載してください（25文字以内）
        - 動画の内容に直接関連したアクションのみを提案してください

        【良い例】
        - 「〇〇をAmazonで検索してカートに入れる」
        - 「〇〇のアプリをダウンロードする」
        - 「〇〇について10分調べる」
        - 「〇〇を試しに1回やってみる」

        【悪い例（これらは提案しないこと）】
        - 「毎日〇〇する習慣をつける」
        - 「〇〇を継続的に改善する」
        - 「週に1回〇〇する」
      PROMPT
    end

    # アクションプラン提案用プロンプト（タイトル＋説明文ベース）
    def build_action_plans_from_title_prompt(title, description)
      desc_text = description.present? ? "\n動画の説明: #{description.truncate(1000)}" : ""

      <<~PROMPT
        以下のYouTube動画について、視聴者が「今日すぐに」実行できる単発アクションを3個提案してください。

        動画タイトル: #{title}#{desc_text}

        【回答形式】
        以下のJSON形式で回答してください。JSONのみを返し、他のテキストは含めないでください。

        {
          "action_plans": [
            "アクション1",
            "アクション2",
            "アクション3"
          ]
        }

        【重要な作成ルール】
        - 必ず3個のアクションを提案してください
        - タイトルから推測される動画内容に基づいて提案してください
        - 「1回で完了する」単発アクションのみ（習慣化や継続的な取り組みはNG）
        - 「今日」「今すぐ」「今週末に」など、すぐに実行できる内容
        - 「〜する」という形式で、短く簡潔に記載してください（25文字以内）

        【良い例】
        - 「〇〇をAmazonで検索してカートに入れる」
        - 「〇〇のアプリをダウンロードする」
        - 「〇〇について10分調べる」
        - 「〇〇を試しに1回やってみる」

        【悪い例（これらは提案しないこと）】
        - 「毎日〇〇する習慣をつける」
        - 「〇〇を継続的に改善する」
        - 「週に1回〇〇する」
      PROMPT
    end

    # アクションプランのJSONレスポンスをパース
    def extract_action_plans(response)
      if response["error"]
        error_message = response.dig("error", "message") || "APIエラーが発生しました"
        Rails.logger.error("Gemini API error response: #{error_message}")

        # レート制限/クォータエラーを検出してユーザーフレンドリーなメッセージを返す
        if error_message.include?("429") || error_message.include?("quota") || error_message.include?("rate")
          return { success: false, error: "AIが混み合っています。約20秒後に再試行してください。", error_type: "rate_limit" }
        end

        return { success: false, error: "アクションプランの生成に失敗しました" }
      end

      text = response.dig("candidates", 0, "content", "parts", 0, "text")

      if text.blank?
        return { success: false, error: "アクションプランを生成できませんでした" }
      end

      # JSONを抽出してパース
      json_match = text.match(/\{[\s\S]*\}/m)
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

        # 3個に制限
        action_plans = action_plans.first(3)

        { success: true, action_plans: action_plans }
      rescue JSON::ParserError => e
        Rails.logger.error("JSON parse error in action plans: #{e.message}")
        { success: false, error: "アクションプランの解析に失敗しました" }
      end
    end

    # アクション提案用プロンプト
    def build_action_prompt(title, transcript)
      <<~PROMPT
        以下はYouTube動画「#{title}」の字幕テキストです。
        この動画を見た視聴者が実践できる具体的なアクションを提案してください。

        【字幕テキスト】
        #{transcript}

        【回答形式】
        動画の内容に基づいて、今日から実践できる具体的なアクションを3〜5個提案してください。
        各アクションは1行で、具体的かつ実行可能な形で記載してください。

        例:
        - 毎朝10分間の瞑想を習慣にする
        - 週に1冊本を読む時間をスケジュールに入れる

        ※ 動画の内容に関連したアクションのみを提案してください。
      PROMPT
    end

    # レスポンスからコンテンツを抽出（generate_entry用）
    def extract_content(response)
      if response["error"]
        error_message = response.dig("error", "message") || "APIエラーが発生しました"
        Rails.logger.error("Gemini API error response: #{error_message}")

        if error_message.include?("429") || error_message.include?("quota")
          return { success: false, error: "APIリクエスト制限に達しました。しばらく待ってから再試行してください。" }
        end

        return { success: false, error: "生成に失敗しました: #{error_message}" }
      end

      text = response.dig("candidates", 0, "content", "parts", 0, "text")

      if text.present?
        { success: true, content: text.strip }
      else
        { success: false, error: "コンテンツを生成できませんでした" }
      end
    end

    # 字幕ベース分析用プロンプト
    def build_transcript_prompt(title, transcript)
      # 字幕が長すぎる場合は切り詰める（トークン制限対策）
      max_chars = 30_000
      truncated_transcript = if transcript.length > max_chars
                               transcript[0, max_chars] + "\n\n（字幕が長いため一部省略）"
                             else
                               transcript
                             end

      <<~PROMPT
        以下はYouTube動画「#{title}」の字幕テキストです。
        この内容を分析し、視聴者向けの学習ガイドを日本語で作成してください。

        【字幕テキスト】
        #{truncated_transcript}

        【回答形式】
        ## この動画で学べること
        動画の主なテーマや学びのポイントを2-3文で要約してください。

        ## 重要なポイント
        動画で述べられている重要なポイントを3-5個、箇条書きで挙げてください。

        ## 視聴後に考えてほしいこと
        - （動画を見た後に自問すべき質問1）
        - （動画を見た後に自問すべき質問2）

        ## 学びを深めるアクション
        動画の内容を踏まえて、実践できる具体的なアクションを2-3個提案してください。

        ## 関連キーワード
        この動画に関連する検索キーワードを3-5個挙げてください。
      PROMPT
    end

    # タイトルベース分析用プロンプト
    def build_title_prompt(title, channel)
      channel_info = channel.present? ? "チャンネル: #{channel}" : ""

      <<~PROMPT
        以下のYouTube動画について、視聴者が学びを深めるための学習ガイドを日本語で作成してください。

        動画タイトル: #{title}
        #{channel_info}

        以下の形式で回答してください：

        ## この動画で学べること
        タイトルから推測される、この動画の主なテーマや学びを2-3文で説明してください。

        ## 視聴前に考えておきたいこと
        - （この動画を見る前に自問すべき質問1）
        - （この動画を見る前に自問すべき質問2）

        ## 学びを深めるアクション
        この動画を見た後に実践できる具体的なアクションを2-3個提案してください。

        ## 関連キーワード
        この動画に関連する検索キーワードを3-5個挙げてください。
      PROMPT
    end

    # コメント分類用プロンプト
    def build_categorize_comments_prompt(comments, video_title)
      title_context = video_title.present? ? "動画「#{video_title}」への" : ""

      comment_list = comments.each_with_index.map do |c, i|
        "#{i + 1}. #{c[:text].to_s.truncate(300)}"
      end.join("\n")

      <<~PROMPT
        あなたはYouTubeコメントの分類エキスパートです。
        以下は#{title_context}YouTubeコメントです。各コメントを最も適切なカテゴリに分類してください。

        【カテゴリと判定基準】

        funny（😂 面白い）:
        - 笑いを狙ったコメント、ボケ、ツッコミ
        - 皮肉やウィットに富んだ表現
        - 面白い言い回しや例え
        - 例：「〇〇で草」「天才すぎる」「センスの塊」

        informative（💡 ためになる）:
        - 動画内容の補足情報や解説
        - 専門知識や背景情報の共有
        - 参考リンクや関連情報
        - 例：「実はこれは〇〇という理由で...」「補足すると...」

        emotional（😭 感動）:
        - 感動や涙を表現するコメント
        - 心が動かされた体験の共有
        - 深い感謝や称賛
        - 例：「泣いた」「鳥肌立った」「心に刺さった」「救われた」

        relatable（🔥 共感）:
        - 「分かる！」「それな」という同意
        - 同じ経験や気持ちの共有
        - 動画の主張への強い賛同
        - 例：「めっちゃ分かる」「自分もそう思ってた」「完全に同意」

        【分類のコツ】
        - 「笑った」だけならfunny、「笑って泣いた」はemotional
        - 単純な称賛（「最高！」「好き」）はrelatable
        - 情報+感想の場合は、メインの意図で判断
        - 迷ったら、コメントを読んだ人が「何を感じるか」で判断

        【コメント一覧】
        #{comment_list}

        【回答形式】
        JSONのみを返してください。説明は不要です。

        {
          "categories": {
            "1": "funny",
            "2": "informative",
            "3": "emotional"
          }
        }
      PROMPT
    end

    # コメント分類レスポンスをパース
    def extract_categorized_comments(response, original_comments)
      if response["error"]
        error_message = response.dig("error", "message") || "APIエラーが発生しました"
        Rails.logger.error("Gemini API error response: #{error_message}")
        return { success: false, error: "コメント分類に失敗しました: #{error_message}" }
      end

      text = response.dig("candidates", 0, "content", "parts", 0, "text")

      if text.blank?
        return { success: false, error: "分類結果を取得できませんでした" }
      end

      # JSONを抽出してパース
      json_match = text.match(/\{[\s\S]*\}/m)
      unless json_match
        Rails.logger.error("Failed to extract JSON from categorize response: #{text}")
        return { success: false, error: "分類データの解析に失敗しました" }
      end

      begin
        data = JSON.parse(json_match[0])
        categories = data["categories"]

        unless categories.is_a?(Hash)
          return { success: false, error: "分類データの形式が不正です" }
        end

        # 元のコメントにカテゴリを追加
        categorized = original_comments.each_with_index.map do |comment, i|
          category = categories[(i + 1).to_s]
          # 有効なカテゴリか確認
          valid_categories = %w[funny informative emotional relatable]
          category = nil unless valid_categories.include?(category)

          comment.merge(category: category)
        end

        { success: true, categorized_comments: categorized }
      rescue JSON::ParserError => e
        Rails.logger.error("JSON parse error in categorize: #{e.message}")
        { success: false, error: "分類データの解析に失敗しました" }
      end
    end

    # レスポンスから要約テキストを抽出
    # @param response [Hash] Gemini APIレスポンス
    # @return [Hash]
    def extract_summary(response)
      # APIエラーレスポンスのチェック
      if response["error"]
        error_message = response.dig("error", "message") || "APIエラーが発生しました"
        Rails.logger.error("Gemini API error response: #{error_message}")

        if error_message.include?("429") || error_message.include?("quota")
          return { success: false, error: "APIリクエスト制限に達しました。しばらく待ってから再試行してください。" }
        end

        return { success: false, error: "分析に失敗しました: #{error_message}" }
      end

      text = response.dig("candidates", 0, "content", "parts", 0, "text")

      if text.present?
        { success: true, summary: text }
      else
        { success: false, error: "ガイドを取得できませんでした" }
      end
    end
  end
end
