# likesテーブルをcheersにリネーム
# 「いいね」機能を「応援」機能にリブランディング

class RenameLikesToCheers < ActiveRecord::Migration[7.2]
  def change
    rename_table :likes, :cheers
  end
end
