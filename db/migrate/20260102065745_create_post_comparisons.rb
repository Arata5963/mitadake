# db/migrate/20260102065745_create_post_comparisons.rb
# ==========================================
# 投稿比較テーブルを作成
# ==========================================
#
# 【このマイグレーションの目的】
# 関連する動画同士の比較・関連付けを管理するテーブルを作成する。
# 「この動画を見た人はこちらも見ています」のような
# レコメンデーション機能の基盤となる。
#
# 【カラムの意味】
# - source_post_id: 比較元の投稿（外部キー）
# - target_post_id: 比較先の投稿（外部キー）
# - reason: 比較・関連付けの理由（テキスト）
#
# 【インデックス】
# - source_post_id + target_post_id: 同じ比較は1回のみ
#
# ==========================================
class CreatePostComparisons < ActiveRecord::Migration[7.2]
  def change
    create_table :post_comparisons do |t|
      t.references :source_post, null: false, foreign_key: { to_table: :posts }
      t.references :target_post, null: false, foreign_key: { to_table: :posts }
      t.text :reason

      t.timestamps
    end

    # 同じ比較は1回のみ（A→Bは一度だけ）
    add_index :post_comparisons, [:source_post_id, :target_post_id], unique: true
  end
end
