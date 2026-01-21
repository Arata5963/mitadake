# app/mailers/application_mailer.rb
# 全メーラーの基底クラス
#
# 現在このアプリではメール送信機能を使用していないが、
# Deviseのパスワードリセットメールなどで将来的に使用される可能性がある
#
# 設定:
# - from: 送信元アドレス（本番環境では適切な値に変更が必要）
# - layout: メールテンプレートのレイアウト（app/views/layouts/mailer.html.erb）
class ApplicationMailer < ActionMailer::Base
  default from: "from@example.com"
  layout "mailer"
end
