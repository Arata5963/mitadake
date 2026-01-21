# db/migrate/20251012002058_add_omniauth_to_users.rb
# ==========================================
# Users テーブルに OmniAuth カラム追加
# ==========================================
#
# 【このマイグレーションの目的】
# Google OAuth 等のSNSログインに対応するため、
# provider と uid カラムを追加する。
#
# 【カラムの意味】
#   provider: 認証プロバイダー名（例: "google_oauth2"）
#   uid:      プロバイダーでのユーザー固有ID
#
# 【使用例】
#   provider = "google_oauth2"
#   uid = "1234567890"
#   これで Google アカウントと紐付けられる
#
# ==========================================

class AddOmniauthToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :provider, :string
    add_column :users, :uid, :string
  end
end
