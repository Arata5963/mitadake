# frozen_string_literal: true

# app/services/transcript_service.rb
# ==========================================
# YouTube字幕取得サービス
# ==========================================
#
# 【このクラスの役割】
# YouTube動画の字幕（キャプション）テキストを取得する。
# GeminiServiceがアクションプランを生成する際に、
# 動画の内容を理解するために使用する。
#
# 【処理の流れ】
#
#   動画ID → Pythonスクリプト実行 → 字幕テキスト
#            ↓
#         youtube-transcript-api
#         (Pythonライブラリ)
#
# 【なぜPythonを使うのか？】
# YouTubeの字幕取得はPythonの「youtube-transcript-api」ライブラリが
# 最も信頼性が高い。RubyにはYouTube公式の字幕APIがないため、
# Pythonスクリプトを呼び出す形で実装している。
#
# 【字幕の優先順位】
# 1. 日本語字幕（手動作成）
# 2. 英語字幕（手動作成）
# 3. 自動生成字幕（日本語）
# 4. 自動生成字幕（英語）
#
# 【依存関係】
# - Python3（Dockerに同梱）
# - youtube-transcript-api パッケージ（pip install済み）
# - lib/scripts/get_transcript.py スクリプト
#
class TranscriptService
  # Pythonスクリプトのパス（Docker内での絶対パス）
  SCRIPT_PATH = "/app/lib/scripts/get_transcript.py"

  # スクリプト実行のタイムアウト（秒）
  # 字幕取得は通常数秒で完了するが、余裕を持って30秒に設定
  TIMEOUT = 30

  # ==========================================
  # クラスメソッドの定義ブロック
  # ==========================================
  class << self
    # ------------------------------------------
    # 動画IDから字幕を取得
    # ------------------------------------------
    # 【何をするメソッド？】
    # YouTube動画の字幕テキストを取得する。
    # 成功/失敗の情報を含むハッシュを返す。
    #
    # 【引数】
    # - video_id: YouTube動画ID（例: "dQw4w9WgXcQ"）
    #
    # 【戻り値】
    # 成功時:
    # {
    #   success: true,
    #   transcript: "字幕のテキスト全文..."
    # }
    #
    # 失敗時:
    # {
    #   success: false,
    #   error: "エラーメッセージ"
    # }
    #
    # 【失敗する主なケース】
    # - 動画に字幕がない
    # - 動画が非公開または削除済み
    # - 字幕がダウンロード禁止になっている
    #
    def fetch_with_status(video_id)
      # 動画IDが空なら即座にエラーを返す
      return { success: false, error: "動画IDがありません" } if video_id.blank?

      # Pythonスクリプトを実行して結果を取得
      result = execute_script(video_id)
      return { success: false, error: "字幕取得に失敗しました" } if result.nil?

      # スクリプトの実行結果を解釈
      if result["success"]
        # 成功: 字幕データをテキストに変換して返す
        {
          success: true,
          transcript: transcript_to_text(result["transcript"])
        }
      else
        # 失敗: エラーメッセージを返す
        {
          success: false,
          error: result["error"] || "字幕取得に失敗しました"
        }
      end
    end

    private

    # ==========================================
    # プライベートメソッド
    # ==========================================

    # ------------------------------------------
    # Pythonスクリプトを実行
    # ------------------------------------------
    # 【何をするメソッド？】
    # get_transcript.py スクリプトを実行し、
    # 字幕データをJSONとして取得する。
    #
    # 【処理の流れ】
    # 1. Open3.capture3 でPythonスクリプトを実行
    # 2. 標準出力、標準エラー出力、終了ステータスを取得
    # 3. 標準出力をJSONとしてパース
    #
    # 【Open3 とは？】
    # Ruby標準ライブラリ。外部コマンドを実行し、
    # その出力を取得するためのモジュール。
    #
    # 【capture3 の戻り値】
    # - stdout: 標準出力（正常な出力）
    # - stderr: 標準エラー出力（エラーメッセージ）
    # - status: 終了ステータス（成功かどうか）
    #
    def execute_script(video_id)
      # Open3 ライブラリを読み込む
      # require は Ruby の import のようなもの
      require "open3"

      # Pythonスクリプトを実行
      # "python3" SCRIPT_PATH video_id を実行する
      stdout, stderr, status = Open3.capture3(
        "python3", SCRIPT_PATH, video_id
      )

      # 実行が失敗した場合
      unless status.success?
        Rails.logger.warn("Transcript script failed: #{stderr}")
        return nil
      end

      # 標準出力をJSONとしてパース
      # Pythonスクリプトは結果をJSON形式で出力する
      JSON.parse(stdout)

    rescue JSON::ParserError => e
      # JSONのパースに失敗した場合
      # Pythonスクリプトが不正な出力をした可能性
      Rails.logger.error("Transcript JSON parse error: #{e.message}")
      nil
    rescue StandardError => e
      # その他のエラー（スクリプトが見つからない等）
      Rails.logger.error("Transcript fetch error: #{e.message}")
      nil
    end

    # ------------------------------------------
    # 字幕データをプレーンテキストに変換
    # ------------------------------------------
    # 【何をするメソッド？】
    # Pythonスクリプトが返す字幕データ（配列形式）を
    # 1つの文字列に結合する。
    #
    # 【入力形式（Pythonからの出力）】
    # [
    #   { "text": "こんにちは", "start": 0.0, "duration": 2.0 },
    #   { "text": "今日は", "start": 2.0, "duration": 1.5 },
    #   { "text": "良い天気ですね", "start": 3.5, "duration": 2.0 }
    # ]
    #
    # 【出力形式】
    # "こんにちは
    # 今日は
    # 良い天気ですね"
    #
    # 【map とは？】
    # 配列の各要素に処理を適用して、新しい配列を作る。
    # ここでは各要素から "text" だけを取り出している。
    #
    # 【join("\n") とは？】
    # 配列の要素を改行で連結して1つの文字列にする。
    #
    def transcript_to_text(transcript_data)
      return nil if transcript_data.blank?

      transcript_data
        .map { |item| item["text"] }  # 各要素から "text" を取り出す
        .join("\n")                    # 改行で連結
    end
  end
end
