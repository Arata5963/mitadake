# Usersテーブルにnameカラム追加
# ユーザーの表示名を保存する（emailとは別にニックネームとして公開可能）

class AddNameToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :name, :string
  end
end
