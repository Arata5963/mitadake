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
