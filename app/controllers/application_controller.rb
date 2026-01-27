# 全コントローラーの基底クラス
# 全てのリクエストで共通して実行される処理を定義

class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?  # Deviseコントローラーでのみ実行

  protected

  # ログアウト後のリダイレクト先を指定
  def after_sign_out_path_for(_resource_or_scope)
    new_user_session_path
  end

  # Deviseの許可パラメータを設定
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :name ])          # サインアップ時にnameを許可
    devise_parameter_sanitizer.permit(:account_update, keys: [ :name ])   # プロフィール更新時にnameを許可
  end
end
