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
