# spec/mailers/application_mailer_spec.rb
# ==========================================
# ApplicationMailer のテスト
# ==========================================
#
# 【このファイルの役割】
# ApplicationMailer（全メーラーの基底クラス）の設定をテストする。
#
# 【テストの実行方法】
#   docker compose exec web rspec spec/mailers/application_mailer_spec.rb
#
# 【テスト対象】
# - デフォルト送信元アドレス設定
# - メーラー継承・作成
# - ActionMailer::Base の継承関係
#
# 【ActionMailerとは？】
# Railsのメール送信機能。HTMLメール、テキストメールを送信できる。
#
#   class UserMailer < ApplicationMailer
#     def welcome_email(user)
#       mail(to: user.email, subject: 'Welcome!')
#     end
#   end
#
#   UserMailer.welcome_email(user).deliver_later  # 非同期送信
#   UserMailer.welcome_email(user).deliver_now    # 即時送信
#
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
