# db/migrate/20250914012202_create_posts.rb
# ==========================================
# Posts テーブル作成（YouTube動画）
# ==========================================
#
# 【このテーブルの役割】
# YouTube動画を管理するテーブル。
# 1動画 = 1レコードとして保存される。
#
# 【初期設計からの変遷】
# 当初は trigger_content（きっかけ）を持っていたが、
# YouTube特化に伴いカラム構成が大きく変更された。
# 現在の最終形は db/schema.rb を参照。
#
# ==========================================

class CreatePosts < ActiveRecord::Migration[7.2]
  def change
    # postsテーブルを新規作成
    create_table :posts do |t|
      # ユーザーとの関連付け（外部キー制約付き）
      # null: false = 必須項目（投稿には必ずユーザーが必要）
      # foreign_key: true = 参照整合性制約（存在しないユーザーIDは登録不可）
      t.references :user, null: false, foreign_key: true

      # きっかけの内容を保存するフィールド
      # text型 = 長文対応（varchar(255)より大容量）
      t.text :trigger_content

      # アクションプランを保存するフィールド
      # text型 = 長文のアクション内容に対応
      t.text :action_plan

      # Rails標準のタイムスタンプフィールド
      # created_at（作成日時）、updated_at（更新日時）を自動追加
      # これによりレコードの作成・更新履歴を自動管理
      t.timestamps
    end
  end
end
