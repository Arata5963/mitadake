# エントリー炎（応援）テーブルを作成
# 後のマイグレーションでentry_likesにリネームされる

class CreateEntryFlames < ActiveRecord::Migration[7.2]
  def change
    create_table :entry_flames do |t|
      t.references :user, null: false, foreign_key: true
      t.references :post_entry, null: false, foreign_key: true
      t.timestamps
    end

    add_index :entry_flames, [ :user_id, :post_entry_id ], unique: true
  end
end
