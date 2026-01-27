# Postsテーブルからtrigger_contentカラム削除
# YouTube特化に伴い、不要になった「きっかけ」入力欄を削除

class RemoveTriggerContentFromPosts < ActiveRecord::Migration[7.2]
  def change
    remove_column :posts, :trigger_content, :text
  end
end
