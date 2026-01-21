# app/controllers/application_controller.rb
# 全コントローラーの基底クラス
# アプリ全体で共通の処理を定義
class ApplicationController < ActionController::Base
  # Deviseコントローラーでは追加パラメータを許可
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  # ログアウト後のリダイレクト先をログインページに設定
  # @return [String] リダイレクト先パス
  def after_sign_out_path_for(_resource_or_scope)
    new_user_session_path
  end

  # Deviseのサインアップ/アカウント更新でnameパラメータを許可
  # デフォルトではemail/passwordのみ許可されているため追加が必要
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :name ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :name ])
  end
end
