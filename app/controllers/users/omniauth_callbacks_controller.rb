# Google OAuth2認証コールバックコントローラー
# Googleログイン後に呼ばれ、ユーザーを作成/ログインさせる

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  # Google OAuth2認証成功時のコールバック（GET/POST /users/auth/google_oauth2/callback）
  def google_oauth2
    auth = request.env["omniauth.auth"]  # Googleからの認証情報

    unless auth
      redirect_to new_user_session_path, alert: "Googleからの情報を取得できませんでした"
      return
    end

    begin
      @user = User.from_omniauth(auth)  # ユーザーを検索/作成
    rescue => e
      Rails.logger.error("[OmniAuth] user save failed: #{e.class} #{e.message}")
      redirect_to new_user_session_path, alert: "ユーザー作成に失敗: #{e.message}"
      return
    end

    if @user.persisted?                                                       # ユーザーが保存されていれば
      sign_in_and_redirect @user, event: :authentication                      # ログインしてリダイレクト
      set_flash_message(:notice, :success, kind: "Google") if is_navigational_format?
    else
      msg = @user.errors.full_messages.first.presence || "不明な理由で失敗しました"
      redirect_to new_user_session_path, alert: "Google認証に失敗しました: #{msg}"
    end
  end

  # 認証失敗時のコールバック（ユーザーがキャンセル等）
  def failure
    type = request.env["omniauth.error.type"]
    err  = request.env["omniauth.error"]&.message || params[:error_description] || params[:message]
    Rails.logger.error("[OmniAuth][failure] type=#{type} message=#{err}")
    redirect_to root_path, alert: "Google認証に失敗しました（#{type}）"
  end
end
