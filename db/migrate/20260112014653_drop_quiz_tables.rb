# db/migrate/20260112014653_drop_quiz_tables.rb
# ==========================================
# クイズ関連テーブルを削除
# ==========================================
#
# 【このマイグレーションの目的】
# クイズ機能の廃止に伴い、関連テーブルを削除する。
# シンプルなアクションプラン管理に注力するため、
# 複雑な理解度テスト機能を削除する。
#
# 【削除されるテーブル】
# - quiz_answers: ユーザーのクイズ回答結果
# - quiz_questions: クイズの問題
# - quizzes: クイズ本体
#
# ==========================================
class DropQuizTables < ActiveRecord::Migration[7.2]
  def change
    drop_table :quiz_answers, if_exists: true
    drop_table :quiz_questions, if_exists: true
    drop_table :quizzes, if_exists: true
  end
end
