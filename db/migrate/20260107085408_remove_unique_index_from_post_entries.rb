# db/migrate/20260107085408_remove_unique_index_from_post_entries.rb
# ==========================================
# エントリーのユニーク制約を削除
# ==========================================
#
# 【このマイグレーションの目的】
# 同一ユーザーが同一動画に複数のアクションプランを投稿できるように、
# user_id + post_id + entry_type のユニーク制約を削除する。
#
# 【変更内容】
# - 削除: idx_unique_user_post_entry_type（ユニークインデックス）
# - 追加: idx_post_entries_user_post（通常の検索用インデックス）
#
# 【ユースケース】
# - 1つの動画から複数の学びを得て、それぞれにアクションプランを作成
# - 過去のアクションプラン達成後に新しいアクションプランを追加
#
# ==========================================
class RemoveUniqueIndexFromPostEntries < ActiveRecord::Migration[7.2]
  def change
    # ユニーク制約を削除（複数アクションプラン投稿を可能にする）
    remove_index :post_entries, name: 'idx_unique_user_post_entry_type'

    # 検索用の通常インデックスを追加
    add_index :post_entries, [:user_id, :post_id], name: 'idx_post_entries_user_post'
  end
end
