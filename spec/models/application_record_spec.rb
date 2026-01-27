# ApplicationRecord のテスト
# 抽象クラス設定と継承関係を検証

require 'rails_helper'

RSpec.describe ApplicationRecord, type: :model do
  describe '基本設定' do
    it 'ApplicationRecordは抽象クラスである' do
      expect(ApplicationRecord.abstract_class?).to be true
    end

    it 'ApplicationRecordを継承したモデルが作成できる' do
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
