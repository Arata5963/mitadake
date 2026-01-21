# spec/models/application_record_spec.rb
# ==========================================
# ApplicationRecord のテスト
# ==========================================
#
# 【このファイルの役割】
# ApplicationRecord（全モデルの基底クラス）の設定をテストする。
#
# 【テストの実行方法】
#   docker compose exec web rspec spec/models/application_record_spec.rb
#
# 【テスト対象】
# - 抽象クラス設定
# - ActiveRecord::Baseの継承関係
# - 既存モデルの継承確認
#
# 【ApplicationRecordとは？】
# Rails 5以降で導入された、全モデルの基底クラス。
# 全モデル共通の設定やメソッドをここに定義できる。
#
#   ApplicationRecord < ActiveRecord::Base
#   User < ApplicationRecord
#   Post < ApplicationRecord
#
require 'rails_helper'

RSpec.describe ApplicationRecord, type: :model do
  describe '基本設定' do
    it 'ApplicationRecordは抽象クラスである' do
      expect(ApplicationRecord.abstract_class?).to be true
    end

    it 'ApplicationRecordを継承したモデルが作成できる' do
      # テスト用のモデルクラスを動的に作成
      test_model = Class.new(ApplicationRecord) do
        self.table_name = 'users'
      end

      expect(test_model.superclass).to eq(ApplicationRecord)
    end
  end

  describe '継承関係' do
    it 'ActiveRecord::Baseを継承している' do
      expect(ApplicationRecord.superclass).to eq(ActiveRecord::Base)
    end

    it '既存モデルがApplicationRecordを継承している' do
      expect(User.superclass).to eq(ApplicationRecord)
      expect(Post.superclass).to eq(ApplicationRecord)
      expect(PostEntry.superclass).to eq(ApplicationRecord)
    end
  end
end
