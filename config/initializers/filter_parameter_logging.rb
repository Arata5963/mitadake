# config/initializers/filter_parameter_logging.rb
# ==========================================
# ログフィルタリング設定
# ==========================================
#
# 【このファイルの役割】
# ログに出力される機密情報をフィルタリング（マスク）する。
# パスワードやトークンなどがログに残らないようにする。
#
# 【なぜフィルタリングが必要？】
#
#   フィルタリングなし:
#   Parameters: {"email"=>"user@example.com", "password"=>"secret123"}
#   ↑ パスワードが丸見え！セキュリティリスク！
#
#   フィルタリングあり:
#   Parameters: {"email"=>"[FILTERED]", "password"=>"[FILTERED]"}
#   ↑ 機密情報が隠される
#
# 【どこに出力されるログ？】
# - log/development.log（開発環境）
# - log/production.log（本番環境）
# - サーバーの標準出力
#
# 【部分一致について】
# :passw は "password", "password_confirmation", "passw" など
# "passw" を含む全てのパラメータにマッチする。
#
# Be sure to restart your server when you modify this file.
#
# Configure parameters to be partially matched (e.g. passw matches password)
# and filtered from the log file.
# Use this to limit dissemination of sensitive information.
# See the ActiveSupport::ParameterFilter documentation for supported notations and behaviors.

Rails.application.config.filter_parameters += [
  # ------------------------------------------
  # フィルタリング対象のパラメータ名
  # ------------------------------------------
  # 部分一致でマッチする（passwはpasswordにもマッチ）
  #
  :passw,        # パスワード関連（password, password_confirmation など）
  :email,        # メールアドレス（プライバシー保護）
  :secret,       # シークレットキー
  :token,        # 認証トークン（APIトークン、リセットトークンなど）
  :_key,         # 各種キー（api_key, secret_key など）
  :crypt,        # 暗号化関連
  :salt,         # ソルト（パスワードハッシュ用）
  :certificate,  # 証明書
  :otp,          # ワンタイムパスワード
  :ssn,          # 社会保障番号（米国）
  :cvv,          # クレジットカードセキュリティコード
  :cvc           # クレジットカードセキュリティコード（別名）
]
