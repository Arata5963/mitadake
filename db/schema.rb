# db/schema.rb
# ==========================================
# データベーススキーマ定義（自動生成）
# ==========================================
#
# 【このファイルの役割】
# データベースの現在の構造を Ruby コードで表現。
# `rails db:schema:load` でこのファイルからDBを再構築できる。
#
# 【重要な注意点】
#   - このファイルを直接編集しないこと！
#   - マイグレーションを作成して `rails db:migrate` を実行する
#   - 実行後、このファイルは自動的に更新される
#
# 【マイグレーションとの関係】
#   db/migrate/*.rb → 変更履歴（差分）
#   db/schema.rb    → 現在の最終状態（スナップショット）
#
# 【新規DB構築時】
#   rails db:schema:load  # マイグレーション不要で高速
#
# 【よく使うコマンド】
#   rails db:migrate         # 未実行のマイグレーションを適用
#   rails db:migrate:status  # マイグレーション実行状況を確認
#   rails db:rollback        # 直前のマイグレーションを取り消し
#
# 【テーブル一覧】
#   - users:             ユーザー（Devise認証）
#   - posts:             YouTube動画（1動画 = 1レコード）
#   - post_entries:      アクションプラン（ユーザーの行動計画）
#   - entry_likes:       いいね（アクションプランへの応援）
#   - solid_queue_*:     バックグラウンドジョブ用テーブル
#
# ==========================================

ActiveRecord::Schema[7.2].define(version: 2026_01_24_100000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "entry_likes", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "post_entry_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["post_entry_id"], name: "index_entry_likes_on_post_entry_id"
    t.index ["user_id", "post_entry_id"], name: "index_entry_likes_on_user_id_and_post_entry_id", unique: true
    t.index ["user_id"], name: "index_entry_likes_on_user_id"
  end

  create_table "post_entries", force: :cascade do |t|
    t.bigint "post_id", null: false
    t.text "content"
    t.date "deadline"
    t.datetime "achieved_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.string "thumbnail_url"
    t.text "reflection"
    t.string "result_image"
    t.index ["post_id", "created_at"], name: "index_post_entries_on_post_id_and_created_at"
    t.index ["post_id"], name: "index_post_entries_on_post_id"
    t.index ["user_id", "post_id"], name: "idx_post_entries_user_post"
    t.index ["user_id"], name: "index_post_entries_on_user_id"
  end

  create_table "posts", force: :cascade do |t|
    t.bigint "user_id"
    t.text "action_plan"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "youtube_url", null: false
    t.string "youtube_title"
    t.string "youtube_channel_name"
    t.string "youtube_video_id"
    t.string "youtube_channel_thumbnail_url"
    t.text "ai_summary"
    t.jsonb "suggested_action_plans"
    t.string "youtube_channel_id"
    t.index ["user_id"], name: "index_posts_on_user_id"
    t.index ["youtube_video_id"], name: "index_posts_on_youtube_video_id", unique: true
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.string "concurrency_key", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.text "error"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "queue_name", null: false
    t.string "class_name", null: false
    t.text "arguments"
    t.integer "priority", default: 0, null: false
    t.string "active_job_id"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.string "queue_name", null: false
    t.datetime "created_at", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.bigint "supervisor_id"
    t.integer "pid", null: false
    t.string "hostname"
    t.text "metadata"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "task_key", null: false
    t.datetime "run_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.string "key", null: false
    t.string "schedule", null: false
    t.string "command", limit: 2048
    t.string "class_name"
    t.text "arguments"
    t.string "queue_name"
    t.integer "priority", default: 0
    t.boolean "static", default: true, null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "scheduled_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.string "key", null: false
    t.integer "value", default: 1, null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "avatar"
    t.string "provider"
    t.string "uid"
    t.string "name"
    t.string "favorite_quote", limit: 50
    t.string "favorite_quote_url"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "entry_likes", "post_entries"
  add_foreign_key "entry_likes", "users"
  add_foreign_key "post_entries", "posts"
  add_foreign_key "post_entries", "users"
  add_foreign_key "posts", "users"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
end
