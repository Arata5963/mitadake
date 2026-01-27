# PostsのdeadlineカラムをNULL許可に変更
# 締め切りを設定しない投稿（情報収集目的など）を許可するため

class ChangeDeadlineNullOnPosts < ActiveRecord::Migration[7.2]
  def change
    change_column_null :posts, :deadline, true
  end
end
