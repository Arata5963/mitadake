# Usersテーブルにavatarカラム追加
# ユーザーのプロフィール画像を保存する（CarrierWaveが画像パスを管理）

class AddAvatarToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :avatar, :string
  end
end
