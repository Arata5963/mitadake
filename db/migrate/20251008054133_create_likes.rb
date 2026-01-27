# Likesテーブル作成（いいね機能）
# 投稿へのいいねを管理する（後にcheersにリネーム、現在はentry_likesに移行）

class CreateLikes < ActiveRecord::Migration[7.2]
  def change
    create_table :likes do |t|
      t.references :user, null: false, foreign_key: true  # いいねしたユーザー
      t.references :post, null: false, foreign_key: true  # いいねされた投稿
      t.timestamps
    end

    add_index :likes, [ :user_id, :post_id ], unique: true # 重複いいね防止
  end
end
