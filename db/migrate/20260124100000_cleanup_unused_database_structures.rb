# db/migrate/20260124100000_cleanup_unused_database_structures.rb
# ==========================================
# 未使用テーブル・カラムの削除
# ==========================================
#
# 【このマイグレーションの目的】
# コードベース調査の結果、使用されていないテーブルとカラムを削除する。
# データベーススキーマを簡素化し、メンテナンス性を向上させる。
#
# 【削除されるテーブル】
# - comments: 動画へのコメント（機能未使用）
# - post_comparisons: 動画比較（モデル削除済み）
# - recommendation_clicks: レコメンドクリック（機能未使用）
# - notifications: 通知（activity_notification gem未使用）
# - subscriptions: 購読（activity_notification gem未使用）
#
# 【削除されるカラム（post_entries）】
# - entry_type: 未使用
# - satisfaction_rating: 未使用
# - title: 未使用
# - published_at: 未使用
# - recommendation_level: 未使用
# - target_audience: 未使用
# - recommendation_point: 未使用
#
# ==========================================
class CleanupUnusedDatabaseStructures < ActiveRecord::Migration[7.2]
  def up
    # ========================================
    # テーブル削除
    # ========================================
    drop_table :comments, if_exists: true
    drop_table :post_comparisons, if_exists: true
    drop_table :recommendation_clicks, if_exists: true
    drop_table :notifications, if_exists: true
    drop_table :subscriptions, if_exists: true

    # ========================================
    # post_entries の未使用カラム削除
    # ========================================
    # まずcheck constraintを削除
    execute <<-SQL
      ALTER TABLE post_entries DROP CONSTRAINT IF EXISTS satisfaction_rating_range;
    SQL

    # カラム削除
    remove_column :post_entries, :entry_type, if_exists: true
    remove_column :post_entries, :satisfaction_rating, if_exists: true
    remove_column :post_entries, :title, if_exists: true
    remove_column :post_entries, :published_at, if_exists: true
    remove_column :post_entries, :recommendation_level, if_exists: true
    remove_column :post_entries, :target_audience, if_exists: true
    remove_column :post_entries, :recommendation_point, if_exists: true
  end

  def down
    # ========================================
    # post_entries のカラム復元
    # ========================================
    add_column :post_entries, :entry_type, :integer, default: 0, null: false
    add_column :post_entries, :satisfaction_rating, :integer
    add_column :post_entries, :title, :string
    add_column :post_entries, :published_at, :datetime
    add_column :post_entries, :recommendation_level, :integer
    add_column :post_entries, :target_audience, :text
    add_column :post_entries, :recommendation_point, :text

    execute <<-SQL
      ALTER TABLE post_entries ADD CONSTRAINT satisfaction_rating_range
      CHECK (satisfaction_rating IS NULL OR satisfaction_rating >= 1 AND satisfaction_rating <= 5);
    SQL

    # ========================================
    # テーブル復元
    # ========================================
    create_table :subscriptions do |t|
      t.string :target_type, null: false
      t.bigint :target_id, null: false
      t.string :key, null: false
      t.boolean :subscribing, default: true, null: false
      t.boolean :subscribing_to_email, default: true, null: false
      t.datetime :subscribed_at
      t.datetime :unsubscribed_at
      t.datetime :subscribed_to_email_at
      t.datetime :unsubscribed_to_email_at
      t.text :optional_targets
      t.timestamps
    end
    add_index :subscriptions, :key
    add_index :subscriptions, [:target_type, :target_id, :key], unique: true
    add_index :subscriptions, [:target_type, :target_id]

    create_table :notifications do |t|
      t.string :target_type, null: false
      t.bigint :target_id, null: false
      t.string :notifiable_type, null: false
      t.bigint :notifiable_id, null: false
      t.string :key, null: false
      t.string :group_type
      t.bigint :group_id
      t.integer :group_owner_id
      t.string :notifier_type
      t.bigint :notifier_id
      t.text :parameters
      t.datetime :opened_at
      t.timestamps
    end
    add_index :notifications, :group_owner_id
    add_index :notifications, [:group_type, :group_id]
    add_index :notifications, [:notifiable_type, :notifiable_id]
    add_index :notifications, [:notifier_type, :notifier_id]
    add_index :notifications, [:target_type, :target_id]

    create_table :recommendation_clicks do |t|
      t.references :post, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.timestamps
    end
    add_index :recommendation_clicks, [:post_id, :user_id], unique: true

    create_table :post_comparisons do |t|
      t.bigint :source_post_id, null: false
      t.bigint :target_post_id, null: false
      t.text :reason
      t.timestamps
    end
    add_index :post_comparisons, [:source_post_id, :target_post_id], unique: true
    add_index :post_comparisons, :source_post_id
    add_index :post_comparisons, :target_post_id
    add_foreign_key :post_comparisons, :posts, column: :source_post_id
    add_foreign_key :post_comparisons, :posts, column: :target_post_id

    create_table :comments do |t|
      t.references :user, null: false, foreign_key: true
      t.references :post, null: false, foreign_key: true
      t.string :content, null: false
      t.timestamps
    end
    add_index :comments, [:post_id, :created_at]
  end
end
