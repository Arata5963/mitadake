# db/migrate/20251008054133_create_likes.rb
# ==========================================
# Likes テーブル作成（いいね機能）
# ==========================================
#
# 【このテーブルの役割】
# 投稿へのいいね（応援）を管理する。
# 中間テーブルとして User と Post を多対多で紐付け。
#
# 【一意制約】
#   [user_id, post_id]: 同じユーザーが同じ投稿に複数回いいね不可
#
# 【現在の状況】
# このテーブルは後のマイグレーションで「cheers」にリネームされた後、
# さらに別のテーブル構成に変更された。
# 現在は entry_likes テーブルが同様の機能を担う。
#
# ==========================================

class CreateLikes < ActiveRecord::Migration[7.2]
  def change
    create_table :likes do |t|
      # 外部キー: ユーザー
      t.references :user, null: false, foreign_key: true

      # 外部キー: 投稿
      t.references :post, null: false, foreign_key: true

      # タイムスタンプ
      t.timestamps
    end

    # 同じユーザーが同じ投稿に複数回いいねできないようにする
    add_index :likes, [ :user_id, :post_id ], unique: true
  end
end
