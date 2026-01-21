#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ==========================================
# YouTube 字幕取得スクリプト（Python）
# ==========================================
#
# 【使い方】Rails の TranscriptService から呼び出される
#
#   TranscriptService.get_transcript(video_id)
#       ↓
#   python3 get_transcript.py <video_id>
#       ↓
#   JSON で字幕データを返す
#
# 【なぜ Python？】
#   Ruby には YouTube 字幕取得の良いライブラリがない。
#   Python の youtube-transcript-api が最も信頼性が高い。
#
# 【関連ファイル】
#   - app/services/transcript_service.rb → このスクリプトを呼び出す
#   - app/services/gemini_service.rb → 字幕を元に AI 分析
#
# 【字幕取得の優先順位】
#   1. 日本語字幕（ja, ja-JP）
#   2. 英語字幕（en, en-US）
#   3. その他利用可能な字幕
#
# ==========================================
"""
YouTube動画の字幕を取得するスクリプト
Usage: python3 get_transcript.py <video_id>

youtube-transcript-api v1.x 対応
"""

import sys
import json
from youtube_transcript_api import YouTubeTranscriptApi


def get_transcript(video_id):
    """
    YouTube動画の字幕を取得する

    Args:
        video_id: YouTube動画ID

    Returns:
        dict: 成功時は {"success": True, "transcript": [...]}
              失敗時は {"success": False, "error": "エラーメッセージ"}
    """
    try:
        ytt_api = YouTubeTranscriptApi()

        # 日本語 → 英語 → 自動生成の順で取得を試みる
        transcript = ytt_api.fetch(video_id, languages=['ja', 'ja-JP', 'en', 'en-US'])

        # FetchedTranscriptオブジェクトをリストに変換
        transcript_data = [
            {"text": item.text, "start": item.start, "duration": item.duration}
            for item in transcript
        ]

        return {"success": True, "transcript": transcript_data}

    except Exception as e:
        error_str = str(e)

        # 特定のエラーメッセージをユーザーフレンドリーに変換
        if "disabled" in error_str.lower():
            return {"success": False, "error": "この動画では字幕が無効になっています"}
        elif "no transcript" in error_str.lower() or "not found" in error_str.lower():
            # 利用可能な字幕を探す
            try:
                transcript_list = ytt_api.list(video_id)
                # 最初に見つかった字幕を取得
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
