# Postsテーブルにrelated_urlカラム追加
# 投稿に関連URLを紐付けられるようにする（後にyoutube_urlにリネーム）

class AddRelatedUrlToPosts < ActiveRecord::Migration[7.2]
  def change
    add_column :posts, :related_url, :string
  end
end
