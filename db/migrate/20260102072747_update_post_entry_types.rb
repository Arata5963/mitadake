# db/migrate/20260102072747_update_post_entry_types.rb
# ==========================================
# 不要なエントリータイプ（nothing）を削除
# ==========================================
#
# 【このマイグレーションの目的】
# entry_type = 2（nothing: 何もしない）のエントリーを削除する。
# 設計変更により「何もしない」という選択肢を廃止したため、
# 既存の該当データを削除する。
#
# 【削除されるデータ】
# - entry_type = 2 のpost_entriesレコード
#
# 【注意】
# - この変更は不可逆（削除されたデータは復元不可）
#
# ==========================================
class UpdatePostEntryTypes < ActiveRecord::Migration[7.2]
  def up
    # nothing (entry_type: 2) のエントリーを削除
    execute "DELETE FROM post_entries WHERE entry_type = 2"
  end

  def down
    # 元に戻す必要はない（削除されたデータは復元不可）
  end
end
