# db/migrate/20251208060840_add_name_to_users.rb
# ==========================================
# Users テーブルに name カラム追加
# ==========================================
#
# 【このマイグレーションの目的】
# ユーザーの表示名を保存できるようにする。
# プロフィールや投稿者名として表示される。
#
# 【なぜ email とは別に name が必要か？】
#   - email はログイン認証用（公開したくない）
#   - name は表示用（ニックネームとして公開可能）
#
# ==========================================

class AddNameToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :name, :string
  end
end
