# db/migrate/20260114053819_create_entry_flames.rb
# ==========================================
# エントリー炎（応援）テーブルを作成
# ==========================================
#
# 【このマイグレーションの目的】
# アクションプランエントリーへの応援（炎）機能のための
# テーブルを作成する。炎アイコンで「燃えろ！頑張れ！」の
# 気持ちを表現できる。
#
# 【カラムの意味】
# - user_id: 炎を付けたユーザーへの外部キー
# - post_entry_id: 炎が付けられたエントリーへの外部キー
#
# 【インデックス】
# - user_id + post_entry_id: 同じユーザーが同じエントリーに
#   重複して炎を付けられないようにする
#
# 【注意】
# - このテーブルは後のマイグレーション（20260119100003）で
#   entry_likesにリネームされる
#
# ==========================================
class CreateEntryFlames < ActiveRecord::Migration[7.2]
  def change
    create_table :entry_flames do |t|
      t.references :user, null: false, foreign_key: true
      t.references :post_entry, null: false, foreign_key: true

      t.timestamps
    end

    # 同じユーザーが同じエントリーに重複して炎を付けられないようにする
    add_index :entry_flames, [ :user_id, :post_entry_id ], unique: true
  end
end
