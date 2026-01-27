# クイズ関連テーブル削除
# クイズ機能の廃止に伴い、quizzes/quiz_questions/quiz_answersを削除

class DropQuizTables < ActiveRecord::Migration[7.2]
  def change
    drop_table :quiz_answers, if_exists: true
    drop_table :quiz_questions, if_exists: true
    drop_table :quizzes, if_exists: true
  end
end
