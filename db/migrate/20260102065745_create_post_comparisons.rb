# PostComparisonsテーブル作成（投稿比較）
# 関連動画のレコメンデーション機能のために動画同士の関連付けを管理

class CreatePostComparisons < ActiveRecord::Migration[7.2]
  def change
    create_table :post_comparisons do |t|
      t.references :source_post, null: false, foreign_key: { to_table: :posts }
      t.references :target_post, null: false, foreign_key: { to_table: :posts }
      t.text :reason

      t.timestamps
    end

    # 同じ比較は1回のみ（A→Bは一度だけ）
    add_index :post_comparisons, [ :source_post_id, :target_post_id ], unique: true
  end
end
