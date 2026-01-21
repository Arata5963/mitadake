# app/controllers/users/omniauth_callbacks_controller.rb
# Google OAuth2認証のコールバック処理
#
# 認証フロー:
# 1. ユーザーがGoogleログインボタンをクリック
# 2. Googleの認証画面にリダイレクト
# 3. 認証成功後、このコントローラーのgoogle_oauth2アクションが呼ばれる
# 4. User.from_omniauthでユーザーを検索/作成してログイン
#
# セキュリティ:
# - CSRF対策としてstate検証を有効化（verify_authenticity_tokenを無効化しない）
class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  # Google OAuth2認証成功時のコールバック
  # @route GET/POST /users/auth/google_oauth2/callback
  def google_oauth2
    auth = request.env["omniauth.auth"]
    unless auth
      redirect_to new_user_session_path, alert: "Googleからの情報を取得できませんでした"
      return
    end

    begin
      @user = User.from_omniauth(auth)
    rescue => e
      Rails.logger.error("[OmniAuth] user save failed: #{e.class} #{e.message}")
      redirect_to new_user_session_path, alert: "ユーザー作成に失敗: #{e.message}"
      return
    end

    if @user.persisted?
      sign_in_and_redirect @user, event: :authentication
      set_flash_message(:notice, :success, kind: "Google") if is_navigational_format?
    else
      msg = @user.errors.full_messages.first.presence || "不明な理由で失敗しました"
      redirect_to new_user_session_path, alert: "Google認証に失敗しました: #{msg}"
    end
  end

  def failure
    type = request.env["omniauth.error.type"]
    err  = request.env["omniauth.error"]&.message ||
           params[:error_description] ||
           params[:message]
    Rails.logger.error("[OmniAuth][failure] type=#{type} message=#{err}")
    redirect_to root_path, alert: "Google認証に失敗しました（#{type}）"
  end
end
