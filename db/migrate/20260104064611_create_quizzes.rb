# db/migrate/20260104064611_create_quizzes.rb
# ==========================================
# クイズテーブルを作成
# ==========================================
#
# 【このマイグレーションの目的】
# 動画の理解度を確認するためのクイズ機能のテーブルを作成する。
# 投稿（動画）に紐づくクイズを管理する。
#
# 【カラムの意味】
# - post_id: 対象の投稿（動画）への外部キー
#
# 【注意】
# - このテーブルは後のマイグレーション（20260112014653）で削除される
#
# ==========================================
class CreateQuizzes < ActiveRecord::Migration[7.2]
  def change
    create_table :quizzes do |t|
      t.references :post, null: false, foreign_key: true

      t.timestamps
    end
  end
end
