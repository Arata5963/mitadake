# spec/jobs/application_job_spec.rb
# ==========================================
# ApplicationJob のテスト
# ==========================================
#
# 【このファイルの役割】
# ApplicationJob（全ジョブの基底クラス）の設定をテストする。
#
# 【テストの実行方法】
#   docker compose exec web rspec spec/jobs/application_job_spec.rb
#
# 【テスト対象】
# - ジョブ作成・実行
# - perform_later でキューに追加
# - ActiveJob::Base の継承関係
#
# 【ActiveJobとは？】
# Railsのバックグラウンドジョブ機能。
# Sidekiq などのジョブ実行基盤と連携できる。
#
#   MyJob.perform_later(args)  # キューに追加
#   MyJob.perform_now(args)    # 即時実行
#
# 【テスト用アダプター】
# テストでは :test アダプターを使用。
# 実際にジョブを実行せず、キューに追加されたかを確認できる。
#
#   ActiveJob::Base.queue_adapter = :test
#   expect { MyJob.perform_later }.to have_enqueued_job(MyJob)
#
require 'rails_helper'

RSpec.describe ApplicationJob, type: :job do
  before do
    ActiveJob::Base.queue_adapter = :test
  end

  describe '基本設定' do
    it 'ApplicationJobを継承したジョブが作成できる' do
      test_job = Class.new(ApplicationJob) do
        def perform(value)
          value * 2
        end
      end

      result = test_job.new.perform(5)
      expect(result).to eq(10)
    end

    it 'perform_laterでジョブをキューに追加できる' do
      test_job = Class.new(ApplicationJob) do
        def perform(*_args); end
      end

      expect {
        test_job.perform_later('test_argument')
      }.to have_enqueued_job(test_job).with('test_argument')
    end
  end

  describe '継承関係' do
    it 'ActiveJob::Baseを継承している' do
      expect(ApplicationJob.superclass).to eq(ActiveJob::Base)
    end
  end
end
