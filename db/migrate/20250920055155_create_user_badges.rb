# db/migrate/20250920055155_create_user_badges.rb
# ==========================================
# UserBadges テーブル作成（バッジ・称号）
# ==========================================
#
# 【このテーブルの役割】
# ユーザーが獲得したバッジ（称号）を管理する。
# ゲーミフィケーション要素として設計された。
#
# 【カラムの意味】
#   user_id:    バッジを獲得したユーザー
#   badge_key:  バッジの種類（"first_post", "10_achievements" 等）
#   awarded_at: 獲得日時
#
# 【現在の状況】
# このテーブルは後のマイグレーションで削除された。
# バッジ機能は実装優先度が下がり、一時的に保留中。
#
# ==========================================

class CreateUserBadges < ActiveRecord::Migration[7.2]
  def change
    create_table :user_badges do |t|
      t.references :user, null: false, foreign_key: true
      t.string :badge_key, null: false
      t.datetime :awarded_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.timestamps
    end

    # 同じバッジは1回のみ獲得可能
    add_index :user_badges, [ :user_id, :badge_key ], unique: true
  end
end
