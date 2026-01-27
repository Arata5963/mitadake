# Postsテーブルにai_summaryカラム追加
# AIが生成した動画の要約文をキャッシュしてアクションプラン作成の参考に

class AddAiSummaryToPosts < ActiveRecord::Migration[7.2]
  def change
    add_column :posts, :ai_summary, :text
  end
end
