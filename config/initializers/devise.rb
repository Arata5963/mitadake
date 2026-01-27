# frozen_string_literal: true

# Devise認証設定
# ログイン、サインアップ、パスワードリセット、Google OAuth2などの動作を制御

Devise.setup do |config|
  # メール送信元アドレス
  config.mailer_sender = "please-change-me-at-config-initializers-devise@example.com"

  # ORM設定（Active Record使用）
  require "devise/orm/active_record"

  # メールアドレスの大文字小文字を区別しない
  config.case_insensitive_keys = [ :email ]

  # メールアドレスの前後の空白を自動除去
  config.strip_whitespace_keys = [ :email ]

  # HTTP認証時はセッションに保存しない
  config.skip_session_storage = [ :http_auth ]

  # パスワードハッシュ強度（テスト環境: 1、本番: 12）
  config.stretches = Rails.env.test? ? 1 : 12

  # メールアドレス変更時に再確認メールを送信
  config.reconfirmable = true

  # ログアウト時に全remember meトークンを無効化
  config.expire_all_remember_me_on_sign_out = true

  # パスワードの長さ制限
  config.password_length = 6..128

  # メールアドレスの形式チェック（@が1つ含まれること）
  config.email_regexp = /\A[^@\s]+@[^@\s]+\z/

  # パスワードリセットトークンの有効期限
  config.reset_password_within = 6.hours

  # Hotwire/Turbo対応フォーマット
  config.navigational_formats = [ "*/*", :html, :turbo_stream ]

  # ログアウトのHTTPメソッド
  config.sign_out_via = :delete

  # Hotwire/Turbo対応HTTPステータス
  config.responder.error_status = :unprocessable_entity
  config.responder.redirect_status = :see_other

  # Google OAuth2設定
  config.omniauth :google_oauth2,
                ENV["GOOGLE_CLIENT_ID"],
                ENV["GOOGLE_CLIENT_SECRET"],
                {
                  scope: "email,profile",         # 取得する情報
                  prompt: "select_account",       # アカウント選択画面を表示
                  image_aspect_ratio: "square",   # プロフィール画像を正方形に
                  image_size: 50
                }
end
