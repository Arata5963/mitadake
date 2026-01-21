# db/migrate/20260105060532_add_ai_summary_to_posts.rb
# ==========================================
# 投稿にAI要約カラムを追加
# ==========================================
#
# 【このマイグレーションの目的】
# YouTube動画のAI生成による要約を保存するカラムを追加する。
# 動画の内容を素早く把握できるようにし、
# アクションプラン作成の参考情報として活用する。
#
# 【カラムの意味】
# - ai_summary: AIが生成した動画の要約文（テキスト）
#   - YouTube Data API のトランスクリプトをベースに生成
#   - キャッシュとして保存し、再生成を防ぐ
#
# ==========================================
class AddAiSummaryToPosts < ActiveRecord::Migration[7.2]
  def change
    add_column :posts, :ai_summary, :text
  end
end
