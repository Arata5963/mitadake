# AI機能バックアップ

**削除日:** 2026-01-30
**理由:** コードをシンプルにするため
**復元時の作業時間目安:** 2-3時間

---

## 削除したファイル一覧

| ファイル | 状態 |
|----------|------|
| `app/services/gemini_service.rb` | 削除 |
| `app/services/transcript_service.rb` | 削除 |
| `lib/scripts/get_transcript.py` | 削除 |
| `spec/services/gemini_service_spec.rb` | 削除 |
| `spec/services/transcript_service_spec.rb` | 削除 |

---

## 1. GeminiService（app/services/gemini_service.rb）

```ruby
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
```

---

## 2. TranscriptService（app/services/transcript_service.rb）

```ruby
# frozen_string_literal: true

# YouTube字幕取得サービス
# Pythonスクリプト経由で動画の字幕テキストを取得

class TranscriptService
  SCRIPT_PATH = "/app/lib/scripts/get_transcript.py"  # Pythonスクリプトパス
  TIMEOUT = 30                                        # タイムアウト（秒）

  class << self
    # 動画IDから字幕を取得（成功/失敗情報を含むハッシュを返す）
    def fetch_with_status(video_id)
      return { success: false, error: "動画IDがありません" } if video_id.blank?

      result = execute_script(video_id)
      return { success: false, error: "字幕取得に失敗しました" } if result.nil?

      if result["success"]
        { success: true, transcript: transcript_to_text(result["transcript"]) }
      else
        { success: false, error: result["error"] || "字幕取得に失敗しました" }
      end
    end

    private

    # Pythonスクリプトを実行して字幕データを取得
    def execute_script(video_id)
      require "open3"

      stdout, stderr, status = Open3.capture3("python3", SCRIPT_PATH, video_id)

      unless status.success?
        Rails.logger.warn("Transcript script failed: #{stderr}")
        return nil
      end

      JSON.parse(stdout)
    rescue JSON::ParserError => e
      Rails.logger.error("Transcript JSON parse error: #{e.message}")
      nil
    rescue StandardError => e
      Rails.logger.error("Transcript fetch error: #{e.message}")
      nil
    end

    # 字幕データをプレーンテキストに変換
    def transcript_to_text(transcript_data)
      return nil if transcript_data.blank?

      transcript_data.map { |item| item["text"] }.join("\n")  # 各字幕のtextを改行で連結
    end
  end
end
```

---

## 3. Pythonスクリプト（lib/scripts/get_transcript.py）

```python
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# YouTube 字幕取得スクリプト
# TranscriptService から python3 get_transcript.py <video_id> で呼び出される

import sys
import json
from youtube_transcript_api import YouTubeTranscriptApi


def get_transcript(video_id):
    """YouTube動画の字幕を取得（日本語→英語→その他の順で試行）"""
    try:
        ytt_api = YouTubeTranscriptApi()
        transcript = ytt_api.fetch(video_id, languages=['ja', 'ja-JP', 'en', 'en-US'])

        transcript_data = [
            {"text": item.text, "start": item.start, "duration": item.duration}
            for item in transcript
        ]
        return {"success": True, "transcript": transcript_data}

    except Exception as e:
        error_str = str(e)

        if "disabled" in error_str.lower():
            return {"success": False, "error": "この動画では字幕が無効になっています"}
        elif "no transcript" in error_str.lower() or "not found" in error_str.lower():
            try:
                transcript_list = ytt_api.list(video_id)
                for t in transcript_list:
                    transcript = t.fetch()
                    transcript_data = [
                        {"text": item.text, "start": item.start, "duration": item.duration}
                        for item in transcript
                    ]
                    return {"success": True, "transcript": transcript_data}
                return {"success": False, "error": "利用可能な字幕が見つかりません"}
            except Exception:
                return {"success": False, "error": "字幕が見つかりません"}
        elif "unavailable" in error_str.lower():
            return {"success": False, "error": "動画が利用できません"}
        else:
            return {"success": False, "error": f"字幕取得エラー: {error_str}"}


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(json.dumps({"success": False, "error": "動画IDが指定されていません"}))
        sys.exit(1)

    video_id = sys.argv[1]
    result = get_transcript(video_id)
    print(json.dumps(result, ensure_ascii=False))
```

---

## 4. PostsController（該当アクション部分）

```ruby
# AIアクションプラン提案を生成
def suggest_action_plans
  video_id = params[:video_id].to_s.strip                                          # 動画IDを取得

  if video_id.blank?                                                               # 動画IDが空の場合
    render json: { success: false, error: "動画IDが必要です" }, status: :unprocessable_entity  # エラーを返す
    return                                                                         # 処理終了
  end

  existing_post = Post.find_by(youtube_video_id: video_id)                         # 既存のPostを検索
  if existing_post&.suggested_action_plans.present?                                # キャッシュがある場合
    render json: { success: true, action_plans: existing_post.suggested_action_plans, cached: true }  # キャッシュを返す
    return                                                                         # 処理終了
  end

  result = GeminiService.suggest_action_plans(                                     # GeminiServiceでAI生成
    video_id: video_id,                                                            # 動画ID
    title: params[:title].to_s.strip,                                              # タイトル
    description: nil                                                               # 説明（省略）
  )

  if result[:success]                                                              # 成功した場合
    existing_post&.update(suggested_action_plans: result[:action_plans])           # キャッシュとして保存
    render json: { success: true, action_plans: result[:action_plans] }            # 成功レスポンス
  else                                                                             # 失敗した場合
    render json: { success: false, error: result[:error] }, status: :unprocessable_entity  # エラーレスポンス
  end
end

# アクションプランをYouTubeタイトル風に変換
def convert_to_youtube_title
  action_plan = params[:action_plan].to_s.strip                                    # アクションプランを取得

  if action_plan.blank?                                                            # 空の場合
    render json: { success: false, error: "アクションプランが必要です" }, status: :unprocessable_entity  # エラーを返す
    return                                                                         # 処理終了
  end

  result = GeminiService.convert_to_youtube_title(action_plan)                     # GeminiServiceで変換

  if result[:success]                                                              # 成功した場合
    render json: { success: true, title: result[:title] }                          # 成功レスポンス
  else                                                                             # 失敗した場合
    render json: { success: false, error: result[:error] }, status: :unprocessable_entity  # エラーレスポンス
  end
end
```

---

## 5. routes.rb（該当行）

```ruby
collection do
  # ...
  post :convert_to_youtube_title                           # タイトル変換
  post :suggest_action_plans                               # AI提案
  # ...
end
```

---

## 6. Stimulusコントローラー（該当メソッド - post_create_controller.js）

```javascript
// AI提案を取得
async fetchAiSuggestions() {
  if (!this.selectedVideo) return
  if (this.hasSuggestButtonTarget) {
    this.suggestButtonTarget.disabled = true
    this.suggestButtonTarget.innerHTML = `<div style="..."></div><span>取得中</span>`
  }
  try {
    const response = await fetchJson(this.suggestUrlValue, {
      method: "POST",
      body: JSON.stringify({ video_id: this.selectedVideo.videoId, title: this.selectedVideo.title })
    })
    const data = await response.json()
    if (data.success && data.action_plans?.length > 0) {
      this.renderSuggestions(data.action_plans)
      if (this.hasSuggestButtonTarget) this.suggestButtonTarget.style.display = "none"
    }
    else { this.showSuggestError("提案を取得できませんでした") }
  } catch (error) {
    console.error("AI suggestion error:", error)
    this.showSuggestError("提案を取得できませんでした")
  }
}

// AI提案を描画
renderSuggestions(plans) {
  if (!this.hasSuggestionsContainerTarget) return
  this.suggestionsContainerTarget.innerHTML = plans.map(plan => `
    <button type="button" data-action="click->post-create#selectSuggestion" data-plan="${escapeHtml(plan)}" class="suggestion-item" ...>
      <span style="flex: 1;">${escapeHtml(plan)}</span>
      <span style="...">選択 →</span>
    </button>`).join("")
}

// AI提案を選択
selectSuggestion(event) {
  const plan = event.currentTarget.dataset.plan
  this.actionPlanInputTarget.value = plan
  this.updateSubmitButton()
  this.updateConvertButton()
  this.updateCollectionPreview()
  this.actionPlanInputTarget.focus()
}

// タイトルをYouTube風に変換
async convertToYouTubeTitle() {
  // ... 省略（バックアップファイル参照）
}
```

---

## 7. ビュー（該当部分 - posts/new.html.erb）

```erb
<%# AI提案ボタン %>
<button type="button"
        data-post-create-target="suggestButton"
        data-action="click->post-create#fetchAiSuggestions"
        class="...">
  AI提案
</button>

<%# タイトル変換ボタン %>
<button type="button"
        data-post-create-target="convertButton"
        data-action="click->post-create#convertToYouTubeTitle"
        class="..." style="display: none;">
  タイトル風に変換
</button>

<%# AI提案の表示エリア %>
<div data-post-create-target="suggestionsContainer"></div>
```

---

## 8. 環境変数

```
GEMINI_API_KEY=your_api_key_here
```

---

## 復元手順

1. このファイルからコードをコピーして各ファイルを作成
2. `config/routes.rb` にルートを追加
3. `posts_controller.rb` にアクションを追加
4. Stimulusコントローラーにメソッドを追加
5. ビューにボタンとコンテナを追加
6. 環境変数 `GEMINI_API_KEY` を設定
7. `pip install youtube-transcript-api` を実行
8. テストを実行して動作確認

---

## 学習用リソース

- **Net::HTTP**: https://docs.ruby-lang.org/ja/latest/class/Net=3a=3aHTTP.html
- **Open3**: https://docs.ruby-lang.org/ja/latest/class/Open3.html
- **Gemini API**: https://ai.google.dev/docs
- **プロンプトエンジニアリング**: プロンプト内の「回答形式」「ルール」「良い例/悪い例」の構造に注目
