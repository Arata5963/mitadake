# Commentsテーブル作成（コメント機能）
# 投稿（YouTube動画）へのコメントを管理する

class CreateComments < ActiveRecord::Migration[7.2]
  def change
    create_table :comments do |t|
      t.references :user, null: false, foreign_key: true  # コメント投稿者
      t.references :post, null: false, foreign_key: true  # 対象の投稿
      t.string :content, null: false                      # コメント本文
      t.timestamps
    end

    add_index :comments, [ :post_id, :created_at ]        # 投稿ごとのコメント一覧取得用
  end
end
