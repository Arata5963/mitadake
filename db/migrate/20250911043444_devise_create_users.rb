# Usersテーブル作成（Devise認証）
# rails generate devise Userで自動生成

class DeviseCreateUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :users do |t|
      t.string :email, null: false, default: ""              # メールアドレス
      t.string :encrypted_password, null: false, default: "" # 暗号化パスワード
      t.string :reset_password_token                         # リセットトークン
      t.datetime :reset_password_sent_at                     # リセット要求日時
      t.datetime :remember_created_at                        # ログイン保持用
      t.timestamps null: false
    end

    add_index :users, :email, unique: true
    add_index :users, :reset_password_token, unique: true
  end
end
