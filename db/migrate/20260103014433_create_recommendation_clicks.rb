# db/migrate/20260103014433_create_recommendation_clicks.rb
# ==========================================
# おすすめクリック記録テーブルを作成
# ==========================================
#
# 【このマイグレーションの目的】
# おすすめ動画がクリックされた回数を記録するテーブルを作成する。
# おすすめの効果測定やランキング機能のために使用される。
#
# 【カラムの意味】
# - post_id: クリックされた投稿への外部キー
# - user_id: クリックしたユーザーへの外部キー
#
# 【インデックス】
# - post_id + user_id: 同じユーザーが同じ投稿に複数回クリックしても
#   カウントは1回（重複防止）
#
# ==========================================
class CreateRecommendationClicks < ActiveRecord::Migration[7.2]
  def change
    create_table :recommendation_clicks do |t|
      t.references :post, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    # 同じユーザーが同じ投稿に複数回クリックしてもカウントは1回
    add_index :recommendation_clicks, [:post_id, :user_id], unique: true
  end
end
