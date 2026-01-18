# frozen_string_literal: true

# Hugging Face APIを使用して画像を生成するサービスクラス
class HuggingfaceService
  # 使用するモデル（FLUX.1-dev - 高品質な画像生成）
  DEFAULT_MODEL = "black-forest-labs/FLUX.1-dev"
  API_URL = "https://router.huggingface.co/hf-inference/models"

  class << self
    # サムネイル画像を生成
    # @param action_plan [String] アクションプラン内容
    # @param style [Symbol] スタイル :chick（ひよこ）がデフォルト
    # @return [Hash] { success: true, image_data: "base64データ" } または { success: false, error: "エラーメッセージ" }
    def generate_thumbnail(action_plan, style: :chick)
      api_key = ENV["HUGGINGFACE_API_KEY"]
      return { success: false, error: "Hugging Face APIキーが設定されていません" } if api_key.blank?
      return { success: false, error: "アクションプランがありません" } if action_plan.blank?

      prompt = build_prompt(action_plan, style)
      Rails.logger.info("HuggingFace generating image with prompt: #{prompt[0..100]}...")

      response = call_api(api_key, prompt)
      process_response(response)
    rescue StandardError => e
      Rails.logger.error("HuggingFace generate_thumbnail error: #{e.message}")
      { success: false, error: "サムネイル生成に失敗しました: #{e.message}" }
    end

    private

    # プロンプトを構築
    def build_prompt(action_plan, style)
      case style
      when :chick
        build_chick_prompt(action_plan)
      else
        build_chick_prompt(action_plan)
      end
    end

    # ひよこキャラクターのプロンプト
    def build_chick_prompt(action_plan)
      # アクションプランからキーワードを抽出して英語に変換
      theme = extract_theme(action_plan)

      <<~PROMPT.strip
        A cute kawaii yellow baby chick character illustration for YouTube thumbnail.
        Theme: #{theme}
        Style: Simple, clean lines, bright cheerful colors, cartoon style, chibi.
        The chick has big expressive eyes, small orange beak, tiny wings.
        Background: Simple gradient or solid color, eye-catching.
        Aspect ratio: 16:9 horizontal format.
        No text, no words in image.
        High quality, professional illustration.
      PROMPT
    end

    # アクションプランからテーマを抽出（簡易的な英語変換）
    def extract_theme(action_plan)
      # キーワードマッピング
      keyword_map = {
        "早起き" => "waking up early, morning sunrise, stretching",
        "朝" => "morning, sunrise",
        "筋トレ" => "exercising, lifting tiny dumbbells, workout",
        "運動" => "exercising, being active",
        "読書" => "reading a book, wearing tiny glasses",
        "本" => "reading, books",
        "勉強" => "studying, learning, with notebook",
        "瞑想" => "meditating peacefully, zen, calm",
        "料理" => "cooking, chef hat, kitchen",
        "掃除" => "cleaning, with tiny broom",
        "断捨離" => "organizing, tidying up, minimalist",
        "水" => "drinking water, staying hydrated",
        "睡眠" => "sleeping well, bedtime, cozy",
        "散歩" => "walking outside, nature",
        "ランニング" => "running, jogging",
        "プログラミング" => "coding, with tiny laptop",
        "英語" => "learning English, studying",
        "貯金" => "saving money, piggy bank",
        "ダイエット" => "eating healthy, fitness"
      }

      # マッチするキーワードを探す
      themes = keyword_map.select { |jp, _en| action_plan.include?(jp) }.values

      if themes.any?
        themes.join(", ")
      else
        # マッチしない場合は汎用的なテーマ
        "achieving a goal, feeling accomplished, celebrating success"
      end
    end

    # Hugging Face APIを呼び出す
    def call_api(api_key, prompt, model: DEFAULT_MODEL)
      uri = URI("#{API_URL}/#{model}")

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = 120 # 画像生成は時間がかかる

      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "Bearer #{api_key}"
      request["Content-Type"] = "application/json"
      request.body = { inputs: prompt }.to_json

      http.request(request)
    end

    # レスポンスを処理
    def process_response(response)
      case response.code.to_i
      when 200
        # 成功: バイナリ画像データが返される
        image_data = Base64.strict_encode64(response.body)
        { success: true, image_data: image_data, mime_type: "image/png" }
      when 503
        # モデルがロード中
        body = JSON.parse(response.body) rescue {}
        estimated_time = body["estimated_time"] || 20
        { success: false, error: "モデルを準備中です。約#{estimated_time.to_i}秒後に再試行してください。", retry_after: estimated_time }
      when 429
        { success: false, error: "レート制限に達しました。しばらく待ってから再試行してください。" }
      else
        body = JSON.parse(response.body) rescue { "error" => response.body }
        error_msg = body["error"] || "不明なエラー"
        Rails.logger.error("HuggingFace API error (#{response.code}): #{error_msg}")
        { success: false, error: "画像生成に失敗しました: #{error_msg}" }
      end
    end
  end
end
