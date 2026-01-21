# db/migrate/20260119022249_add_reflection_and_result_image_to_post_entries.rb
# ==========================================
# エントリーに振り返りと結果画像カラムを追加
# ==========================================
#
# 【このマイグレーションの目的】
# アクションプラン達成時の振り返り機能を強化するため、
# 振り返りテキストと結果画像を保存するカラムを追加する。
#
# 【カラムの意味】
# - reflection: 振り返りテキスト（達成後の感想、学び）
# - result_image: 結果を示す画像のURL/パス（CarrierWave管理）
#   - 例: ビフォーアフター写真、完成した作品の写真など
#
# ==========================================
class AddReflectionAndResultImageToPostEntries < ActiveRecord::Migration[7.2]
  def change
    add_column :post_entries, :reflection, :text
    add_column :post_entries, :result_image, :string
  end
end
