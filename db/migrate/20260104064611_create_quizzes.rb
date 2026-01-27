# Quizzesテーブル作成（クイズ機能）
# 動画の理解度確認クイズを管理する（後のマイグレーションで削除済み）

class CreateQuizzes < ActiveRecord::Migration[7.2]
  def change
    create_table :quizzes do |t|
      t.references :post, null: false, foreign_key: true

      t.timestamps
    end
  end
end
