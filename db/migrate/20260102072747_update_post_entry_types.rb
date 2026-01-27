# 不要なエントリータイプ（nothing）を削除
# 設計変更により「何もしない」選択肢を廃止、該当データを削除（不可逆）

class UpdatePostEntryTypes < ActiveRecord::Migration[7.2]
  def up
    # nothing (entry_type: 2) のエントリーを削除
    execute "DELETE FROM post_entries WHERE entry_type = 2"
  end

  def down
    # 元に戻す必要はない（削除されたデータは復元不可）
  end
end
