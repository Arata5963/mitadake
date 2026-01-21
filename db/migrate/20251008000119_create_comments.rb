# db/migrate/20251008000119_create_comments.rb
# ==========================================
# Comments テーブル作成（コメント機能）
# ==========================================
#
# 【このテーブルの役割】
# 投稿（YouTube動画）へのコメントを管理する。
# ユーザー同士のコミュニケーション機能。
#
# 【関連】
#   User has_many :comments
#   Post has_many :comments
#
# 【インデックス】
#   [post_id, created_at]: 投稿ごとのコメント一覧を高速取得
#
# ==========================================

class CreateComments < ActiveRecord::Migration[7.2]
  def change
    # commentsテーブルを新規作成
    create_table :comments do |t|
      # ユーザーとの関連付け(外部キー制約付き)
      # null: false = 必須項目(コメントには必ずユーザーが必要)
      # foreign_key: true = 参照整合性制約(存在しないユーザーIDは登録不可)
      t.references :user, null: false, foreign_key: true

      # 投稿との関連付け(外部キー制約付き)
      # どの投稿に対するコメントかを識別
      t.references :post, null: false, foreign_key: true

      # コメント本文
      # null: false = 必須項目(空コメントは不可)
      t.string :content, null: false

      # Rails標準のタイムスタンプフィールド
      # created_at(作成日時)、updated_at(更新日時)を自動追加
      t.timestamps
    end

    # パフォーマンス最適化のためのインデックス追加
    # 特定の投稿に紐づくコメント一覧を高速取得するため
    add_index :comments, [ :post_id, :created_at ]
  end
end
