# app/mailers/application_mailer.rb
# ==========================================
# メーラー基底クラス
# ==========================================
#
# 【このファイルの役割】
# 全てのメーラークラスの親となる基底クラス。
# メール送信の共通設定を定義する。
#
# 【メーラー（Mailer）とは？】
# Railsでメール送信を行うためのクラス。
# コントローラーのようにアクションを持ち、
# ビュー（メールテンプレート）をレンダリングして送信する。
#
# 【現在の使用状況】
# このアプリでは現在メール送信機能を使用していないが、
# 将来的に以下の用途で使用される可能性がある:
# - Deviseのパスワードリセットメール
# - 達成通知メール
# - リマインダーメール
#
# 【クラス継承の関係】
#
#   ActionMailer::Base（Rails標準）
#         ↓
#   ApplicationMailer（このファイル）
#         ↓
#   各種メーラー（UserMailer, NotificationMailer など）
#
# 【設定項目】
# - default from: メール送信元アドレス
# - layout: メールテンプレートのレイアウトファイル
#
# 【関連ファイル】
# - app/views/layouts/mailer.html.erb: HTMLメールのレイアウト
# - app/views/layouts/mailer.text.erb: テキストメールのレイアウト
# - config/environments/*.rb: メール送信設定（SMTP等）
#
class ApplicationMailer < ActionMailer::Base
  # ------------------------------------------
  # デフォルト設定
  # ------------------------------------------
  # from: メール送信元アドレス
  # 本番環境では適切なドメインのアドレスに変更が必要
  # 例: noreply@mitadake.example.com
  #
  default from: "from@example.com"

  # ------------------------------------------
  # レイアウト設定
  # ------------------------------------------
  # メールテンプレートで使用するレイアウトファイルを指定
  # app/views/layouts/mailer.html.erb が使われる
  #
  layout "mailer"
end
