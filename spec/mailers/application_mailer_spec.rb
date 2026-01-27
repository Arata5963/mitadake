# ApplicationMailer のテスト
# メーラー基底クラスの設定と継承関係を検証

require 'rails_helper'

RSpec.describe ApplicationMailer, type: :mailer do
  describe '基本設定' do
    it 'デフォルトの送信元アドレスが設定されている' do
      expect(ApplicationMailer.default[:from]).to be_present
    end

    it 'ApplicationMailerを継承したメーラーが作成できる' do
      test_mailer = Class.new(ApplicationMailer) do
        def test_email
          mail(to: 'test@example.com', subject: 'Test Email') do |format|
            format.text { render plain: 'Test Body' }
          end
        end
      end

      email = test_mailer.new.test_email
      expect(email.to).to eq([ 'test@example.com' ])
      expect(email.subject).to eq('Test Email')
    end
  end

  describe '継承関係' do
    it 'ActionMailer::Baseを継承している' do
      expect(ApplicationMailer.superclass).to eq(ActionMailer::Base)
    end
  end
end
