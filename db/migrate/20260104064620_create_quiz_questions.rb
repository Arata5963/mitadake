# db/migrate/20260104064620_create_quiz_questions.rb
# ==========================================
# クイズ問題テーブルを作成
# ==========================================
#
# 【このマイグレーションの目的】
# クイズの個別問題を管理するテーブルを作成する。
# 4択問題形式で、正解の選択肢番号を記録する。
#
# 【カラムの意味】
# - quiz_id: 所属するクイズへの外部キー
# - question_text: 問題文
# - option_1〜4: 選択肢1〜4のテキスト
# - correct_option: 正解の選択肢番号（1〜4）
# - position: 問題の表示順序
#
# 【注意】
# - このテーブルは後のマイグレーション（20260112014653）で削除される
#
# ==========================================
class CreateQuizQuestions < ActiveRecord::Migration[7.2]
  def change
    create_table :quiz_questions do |t|
      t.references :quiz, null: false, foreign_key: true
      t.text :question_text
      t.string :option_1
      t.string :option_2
      t.string :option_3
      t.string :option_4
      t.integer :correct_option
      t.integer :position

      t.timestamps
    end
  end
end
