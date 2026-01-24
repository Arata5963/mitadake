# app/controllers/application_controller.rb
# ==========================================
# 全コントローラーの基底クラス
# ==========================================
#
# 【このクラスの役割】
# アプリ内の全てのコントローラーはこのクラスを継承する。
# ここに書いた処理は、全てのコントローラーで共通して実行される。
#
# 【コントローラーとは？】
# MVCアーキテクチャの「C」。
# ユーザーからのリクエストを受け取り、
# モデルを操作してビューを返す役割。
#
# 【継承関係】
#
#   ActionController::Base（Rails提供）
#          ↑
#   ApplicationController（このクラス）
#          ↑
#   ├── PostsController
#   ├── PostEntriesController
#   ├── UsersController
#   ├── PagesController
#   └── Api::PresignedUrlsController
#
# 【ActionController::Base とは？】
# Railsが提供するコントローラーの基底クラス。
# リクエスト処理、レスポンス生成、セッション管理など
# コントローラーに必要な機能が全て含まれている。
#
class ApplicationController < ActionController::Base
  # ==========================================
  # before_action（各アクションの前に実行）
  # ==========================================
  #
  # 【before_action とは？】
  # コントローラーのアクション（index, show, create等）が
  # 実行される前に呼ばれるメソッドを指定する。
  #
  # 【if: :devise_controller? とは？】
  # 条件付きbefore_action。
  # Deviseのコントローラー（ログイン画面等）の場合のみ実行される。
  #
  # Deviseコントローラーでは追加パラメータを許可する必要があるため、
  # この設定を行っている。
  #
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  # ==========================================
  # protectedメソッド
  # ==========================================
  #
  # 【protected とは？】
  # このクラスと、このクラスを継承したクラスからのみ呼べるメソッド。
  # 外部（ビュー等）からは呼べない。
  # private よりは緩く、public よりは厳しいアクセス制限。
  #

  # ------------------------------------------
  # ログアウト後のリダイレクト先
  # ------------------------------------------
  # 【何をするメソッド？】
  # ユーザーがログアウトした後に、どのページに
  # リダイレクトするかを指定する。
  #
  # 【Deviseのオーバーライド】
  # Deviseにはデフォルトのリダイレクト先があるが、
  # このメソッドをオーバーライドすることでカスタマイズできる。
  #
  # 【_resource_or_scope とは？】
  # 引数名の先頭に _ がついているのは、
  # 「この引数は使わない」という慣習的な書き方。
  # Linterの警告を避けるため。
  #
  def after_sign_out_path_for(_resource_or_scope)
    # ログアウト後はログインページに遷移
    new_user_session_path
  end

  # ------------------------------------------
  # Deviseの許可パラメータ設定
  # ------------------------------------------
  # 【何をするメソッド？】
  # Deviseのサインアップ・アカウント更新時に、
  # 追加のパラメータ（name）を受け付けるように設定する。
  #
  # 【なぜ必要か？】
  # Deviseはデフォルトでemail/passwordのみ許可している。
  # Userモデルにnameカラムを追加した場合、
  # ここで明示的に許可しないとフォームから送信できない。
  #
  # 【Strong Parameters】
  # Railsのセキュリティ機能。
  # フォームから送信されたデータのうち、
  # 許可したパラメータのみをモデルに渡す。
  # これにより、意図しないカラムの更新を防ぐ。
  #
  # 【devise_parameter_sanitizer とは？】
  # Deviseが提供するStrong Parametersの設定ヘルパー。
  # :sign_up はサインアップ時、:account_update はプロフィール更新時。
  #
  def configure_permitted_parameters
    # サインアップ時にnameを許可
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :name ])
    # プロフィール更新時にnameを許可
    devise_parameter_sanitizer.permit(:account_update, keys: [ :name ])
  end
end
