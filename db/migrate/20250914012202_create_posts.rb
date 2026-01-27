# Postsテーブル作成
# YouTube動画を管理するテーブル（1動画 = 1レコード）

class CreatePosts < ActiveRecord::Migration[7.2]
  def change
    create_table :posts do |t|
      t.references :user, null: false, foreign_key: true
      t.text :trigger_content
      t.text :action_plan
      t.timestamps
    end
  end
end
