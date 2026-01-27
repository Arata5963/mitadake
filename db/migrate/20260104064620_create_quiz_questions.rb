# QuizQuestionsテーブル作成（クイズ問題）
# クイズの個別問題を4択形式で管理する（後のマイグレーションで削除済み）

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
