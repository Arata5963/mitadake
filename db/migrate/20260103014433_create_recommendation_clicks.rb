# RecommendationClicksテーブル作成（おすすめクリック記録）
# おすすめ動画がクリックされた回数を記録し、効果測定やランキングに使用

class CreateRecommendationClicks < ActiveRecord::Migration[7.2]
  def change
    create_table :recommendation_clicks do |t|
      t.references :post, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    # 同じユーザーが同じ投稿に複数回クリックしてもカウントは1回
    add_index :recommendation_clicks, [ :post_id, :user_id ], unique: true
  end
end
