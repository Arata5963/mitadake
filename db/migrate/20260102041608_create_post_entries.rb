# db/migrate/20260102041608_create_post_entries.rb
# ==========================================
# PostEntries テーブル作成（アクションプラン）
# ==========================================
#
# 【このテーブルの役割】
# ユーザーが動画から得たアクションプランを管理する。
# Post（動画）とUser（ユーザー）の中間テーブル的役割。
#
# 【カラムの意味】
#   post_id:      どの動画からのアクションプランか
#   entry_type:   種類（0=action、1=blog、2=recommend等）
#   content:      アクションプランの内容
#   deadline:     期限（締切日）
#   achieved_at:  達成日時（NULL=未達成）
#
# ==========================================

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
