# PostEntriesテーブル作成
# ユーザーのアクションプランを管理する中間テーブル

class CreatePostEntries < ActiveRecord::Migration[7.2]
  def change
    create_table :post_entries do |t|
      t.references :post, null: false, foreign_key: true
      t.integer :entry_type, null: false, default: 0
      t.text :content
      t.date :deadline
      t.datetime :achieved_at

      t.timestamps
    end

    add_index :post_entries, %i[post_id created_at]
  end
end
