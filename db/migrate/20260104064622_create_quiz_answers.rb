# db/migrate/20260104064622_create_quiz_answers.rb
# ==========================================
# クイズ回答テーブルを作成
# ==========================================
#
# 【このマイグレーションの目的】
# ユーザーのクイズ回答結果を記録するテーブルを作成する。
# スコアと問題数を保存し、正答率を計算できるようにする。
#
# 【カラムの意味】
# - user_id: 回答したユーザーへの外部キー
# - quiz_id: 回答したクイズへの外部キー
# - score: 正解数
# - total_questions: 出題数
#
# 【注意】
# - このテーブルは後のマイグレーション（20260112014653）で削除される
#
# ==========================================
class CreateQuizAnswers < ActiveRecord::Migration[7.2]
  def change
    create_table :quiz_answers do |t|
      t.references :user, null: false, foreign_key: true
      t.references :quiz, null: false, foreign_key: true
      t.integer :score
      t.integer :total_questions

      t.timestamps
    end
  end
end
