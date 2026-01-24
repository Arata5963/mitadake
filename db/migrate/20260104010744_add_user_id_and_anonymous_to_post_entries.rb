# db/migrate/20260104010744_add_user_id_and_anonymous_to_post_entries.rb
# ==========================================
# エントリーにユーザーIDと匿名フラグを追加
# ==========================================
#
# 【このマイグレーションの目的】
# エントリーを投稿したユーザーを直接参照できるようにする。
# また、匿名投稿を可能にする機能を追加する。
#
# 【カラムの意味】
# - user_id: 投稿したユーザーへの外部キー（NULL許可 = 匿名投稿）
# - anonymous: 匿名表示フラグ（true = ユーザー名を非表示）
#
# 【インデックス】
# - user_id + post_id + entry_type: 同一ユーザー・投稿・タイプの
#   組み合わせを一意に保つ
#
# ==========================================
class AddUserIdAndAnonymousToPostEntries < ActiveRecord::Migration[7.2]
  def change
    add_reference :post_entries, :user, null: true, foreign_key: true
    add_column :post_entries, :anonymous, :boolean, default: false, null: false
    add_index :post_entries, [ :user_id, :post_id, :entry_type ],
              unique: true, name: 'idx_unique_user_post_entry_type'
  end
end
