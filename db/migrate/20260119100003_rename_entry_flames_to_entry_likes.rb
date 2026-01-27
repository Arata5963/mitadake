# entry_flamesテーブルをentry_likesにリネーム
# 「炎」から「いいね」への呼称変更に伴うテーブル名変更

class RenameEntryFlamesToEntryLikes < ActiveRecord::Migration[7.2]
  def change
    rename_table :entry_flames, :entry_likes
  end
end
