# app/controllers/users/omniauth_callbacks_controller.rb
# ==========================================
# Google OAuth2認証コールバック
# ==========================================
#
# 【このクラスの役割】
# Googleでログインした後に呼ばれるコントローラー。
# Googleから受け取った認証情報を使ってユーザーを作成/ログインさせる。
#
# 【OAuth2認証フロー】
#
#   1. ユーザーが「Googleでログイン」ボタンをクリック
#      ↓
#   2. Googleの認証画面にリダイレクト
#      ↓
#   3. ユーザーがGoogleで認証（同意画面）
#      ↓
#   4. Googleがこのコントローラーにリダイレクト（callback）
#      ↓
#   5. google_oauth2 アクションが実行される
#      ↓
#   6. User.from_omniauth でユーザーを検索/作成
#      ↓
#   7. ログイン完了、トップページへリダイレクト
#
# 【なぜ Users:: 名前空間か？】
# Deviseの規約。認証関連のコントローラーは
# users/ ディレクトリに配置する。
#
# 【継承について】
# Devise::OmniauthCallbacksController を継承している。
# これはDeviseが提供するOAuth用の基底クラス。
#
class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  # ------------------------------------------
  # Google OAuth2認証成功時のコールバック
  # ------------------------------------------
  # 【ルート】GET/POST /users/auth/google_oauth2/callback
  #
  # 【何をするメソッド？】
  # Googleからの認証情報を受け取り、
  # ユーザーを検索または作成してログインさせる。
  #
  # 【request.env["omniauth.auth"] とは？】
  # OmniAuthがリクエストに格納した認証情報。
  # 以下のような構造:
  # {
  #   provider: "google_oauth2",
  #   uid: "123456789",
  #   info: {
  #     email: "user@gmail.com",
  #     name: "山田太郎"
  #   }
  # }
  #
  def google_oauth2
    # Googleからの認証情報を取得
    auth = request.env["omniauth.auth"]

    # 認証情報がない場合（通常は発生しない）
    unless auth
      redirect_to new_user_session_path, alert: "Googleからの情報を取得できませんでした"
      return
    end

    begin
      # User.from_omniauth でユーザーを検索/作成
      # 詳細は app/models/user.rb を参照
      @user = User.from_omniauth(auth)
    rescue => e
      # ユーザー作成に失敗した場合
      Rails.logger.error("[OmniAuth] user save failed: #{e.class} #{e.message}")
      redirect_to new_user_session_path, alert: "ユーザー作成に失敗: #{e.message}"
      return
    end

    # ユーザーが正常に保存されているか確認
    if @user.persisted?
      # 【sign_in_and_redirect とは？】
      # Deviseが提供するメソッド。
      # ユーザーをログインさせ、適切なページにリダイレクトする。
      #
      # 【event: :authentication とは？】
      # ログインイベントの種類を指定。
      # これにより、Deviseのログインフックが正しく動作する。
      sign_in_and_redirect @user, event: :authentication

      # 【set_flash_message とは？】
      # Deviseのフラッシュメッセージ設定メソッド。
      # :success は成功メッセージ、kind: "Google" で
      # 「Googleでログインしました」のようなメッセージになる。
      set_flash_message(:notice, :success, kind: "Google") if is_navigational_format?
    else
      # ユーザーの保存に失敗した場合
      msg = @user.errors.full_messages.first.presence || "不明な理由で失敗しました"
      redirect_to new_user_session_path, alert: "Google認証に失敗しました: #{msg}"
    end
  end

  # ------------------------------------------
  # 認証失敗時のコールバック
  # ------------------------------------------
  # 【何をするメソッド？】
  # ユーザーがGoogleの認証画面でキャンセルした場合や、
  # 認証に失敗した場合に呼ばれる。
  #
  # 【request.env["omniauth.error.type"] とは？】
  # OmniAuthがセットするエラーの種類。
  # 例: "access_denied"（ユーザーがキャンセル）
  #
  def failure
    type = request.env["omniauth.error.type"]
    err  = request.env["omniauth.error"]&.message ||
           params[:error_description] ||
           params[:message]
    Rails.logger.error("[OmniAuth][failure] type=#{type} message=#{err}")
    redirect_to root_path, alert: "Google認証に失敗しました（#{type}）"
  end
end
