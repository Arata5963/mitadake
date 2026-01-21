# frozen_string_literal: true

# YouTube動画の字幕を取得するサービスクラス
class TranscriptService
  SCRIPT_PATH = "/app/lib/scripts/get_transcript.py"
  TIMEOUT = 30 # 秒

  class << self
    # 動画IDから字幕取得を試み、結果を詳細に返す
    # @param video_id [String] YouTube動画ID
    # @return [Hash] { success: true/false, transcript: "...", error: "..." }
    def fetch_with_status(video_id)
      return { success: false, error: "動画IDがありません" } if video_id.blank?

      result = execute_script(video_id)
      return { success: false, error: "字幕取得に失敗しました" } if result.nil?

      if result["success"]
        {
          success: true,
          transcript: transcript_to_text(result["transcript"])
        }
      else
        {
          success: false,
          error: result["error"] || "字幕取得に失敗しました"
        }
      end
    end

    private

    # Pythonスクリプトを実行して結果を取得
    def execute_script(video_id)
      require "open3"

      stdout, stderr, status = Open3.capture3(
        "python3", SCRIPT_PATH, video_id
      )

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

      transcript_data
        .map { |item| item["text"] }
        .join("\n")
    end
  end
end
