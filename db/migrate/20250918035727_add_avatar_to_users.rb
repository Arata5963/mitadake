# db/migrate/20250918035727_add_avatar_to_users.rb
# ==========================================
# Users テーブルに avatar カラム追加
# ==========================================
#
# 【このマイグレーションの目的】
# ユーザーのプロフィール画像（アバター）を保存する。
# CarrierWave の ImageUploader が画像パスを管理。
#
# 【保存される値の例】
#   "uploads/user/avatar/1/sample.jpg"
#   AWS S3 使用時は S3 のパスが保存される
#
# ==========================================

class AddAvatarToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :avatar, :string
  end
end
