# PostEntriesテーブルに振り返りと結果画像カラム追加
# アクションプラン達成時の振り返りテキストと結果画像を保存

class AddReflectionAndResultImageToPostEntries < ActiveRecord::Migration[7.2]
  def change
    add_column :post_entries, :reflection, :text
    add_column :post_entries, :result_image, :string
  end
end
