# ジョブ基底クラス
# 全てのバックグラウンドジョブの親クラス

class ApplicationJob < ActiveJob::Base
  # retry_on ActiveRecord::Deadlocked          # デッドロック時は自動リトライ
  # discard_on ActiveJob::DeserializationError # レコード削除時はジョブ破棄
end
