# ログフィルタリング設定
# パスワードやトークンなど機密情報をログに出力しないよう[FILTERED]でマスク

Rails.application.config.filter_parameters += [
  :passw,        # パスワード関連
  :email,        # メールアドレス
  :secret,       # シークレットキー
  :token,        # 認証トークン
  :_key,         # 各種キー（api_key等）
  :crypt,        # 暗号化関連
  :salt,         # ソルト
  :certificate,  # 証明書
  :otp,          # ワンタイムパスワード
  :ssn,          # 社会保障番号
  :cvv,          # クレジットカードCVV
  :cvc           # クレジットカードCVC
]
