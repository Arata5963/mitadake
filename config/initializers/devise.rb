# frozen_string_literal: true

# config/initializers/devise.rb
# ==========================================
# Devise 認証設定ファイル
# ==========================================
#
# 【このファイルの役割】
# Devise（認証ライブラリ）のグローバル設定を定義する。
# ログイン、サインアップ、パスワードリセットなどの動作を制御。
#
# 【Deviseとは？】
# Railsで最もよく使われる認証ライブラリ。
# ユーザー登録、ログイン、パスワードリセット、
# OAuth連携などを簡単に実装できる。
#
# 【このアプリでの使用モジュール】
#
#   :database_authenticatable  → メール+パスワード認証
#   :registerable              → ユーザー登録機能
#   :recoverable               → パスワードリセット
#   :rememberable              → 「ログイン状態を保持」
#   :validatable               → メール・パスワードのバリデーション
#   :omniauthable              → OAuth認証（Google）
#
# 【関連ファイル】
# - app/models/user.rb: deviseマクロを使用
# - app/controllers/users/omniauth_callbacks_controller.rb: OAuth処理
# - config/routes.rb: devise_for :users
#
# Assuming you have not yet modified this file, each configuration option below
# is set to its default value. Note that some are commented out while others
# are not: uncommented lines are intended to protect your configuration from
# breaking changes in upgrades (i.e., in the event that future versions of
# Devise change the default values for those options).
#
# Use this hook to configure devise mailer, warden hooks and so forth.
# Many of these configuration options can be set straight in your model.
Devise.setup do |config|
  # ------------------------------------------
  # シークレットキー設定
  # ------------------------------------------
  # Deviseがトークン生成に使用するシークレットキー。
  # デフォルトではRailsのsecret_key_baseを使用。
  #
  # The secret key used by Devise. Devise uses this key to generate
  # random tokens. Changing this key will render invalid all existing
  # confirmation, reset password and unlock tokens in the database.
  # Devise will use the `secret_key_base` as its `secret_key`
  # by default. You can change it below and use your own secret key.
  # config.secret_key = 'b37d64077c64b6cebc6c50a0998d2e46b6f704c49ce298db52b98aeb1f49e04ea4fd4ea8c9171b3bf1c8c95f0f8e3ef7f2ffe2e695a42024a5208d67e6d91483'

  # ==> Controller configuration
  # Configure the parent class to the devise controllers.
  # config.parent_controller = 'DeviseController'

  # ------------------------------------------
  # メール設定
  # ------------------------------------------
  # 【mailer_sender】
  # Deviseから送信されるメールの送信元アドレス。
  # パスワードリセットメールなどに使用。
  #
  # ==> Mailer Configuration
  # Configure the e-mail address which will be shown in Devise::Mailer,
  # note that it will be overwritten if you use your own mailer class
  # with default "from" parameter.
  config.mailer_sender = "please-change-me-at-config-initializers-devise@example.com"

  # Configure the class responsible to send e-mails.
  # config.mailer = 'Devise::Mailer'

  # Configure the parent class responsible to send e-mails.
  # config.parent_mailer = 'ActionMailer::Base'

  # ------------------------------------------
  # ORM設定
  # ------------------------------------------
  # 【ORMとは？】
  # Object-Relational Mapping（オブジェクト関係マッピング）
  # RubyオブジェクトとDBを橋渡しする仕組み。
  # RailsではActive Recordがデフォルト。
  #
  # ==> ORM configuration
  # Load and configure the ORM. Supports :active_record (default) and
  # :mongoid (bson_ext recommended) by default. Other ORMs may be
  # available as additional gems.
  require "devise/orm/active_record"

  # ------------------------------------------
  # 認証キー設定
  # ------------------------------------------
  # 【authentication_keys】
  # ログイン時に使用する識別子。
  # デフォルトは :email（メールアドレス）。
  # ユーザー名でログインしたい場合は [:username] に変更。
  #
  # ==> Configuration for any authentication mechanism
  # Configure which keys are used when authenticating a user. The default is
  # just :email. You can configure it to use [:username, :subdomain], so for
  # authenticating a user, both parameters are required. Remember that those
  # parameters are used only when authenticating and not when retrieving from
  # session. If you need permissions, you should implement that in a before filter.
  # You can also supply a hash where the value is a boolean determining whether
  # or not authentication should be aborted when the value is not present.
  # config.authentication_keys = [:email]

  # Configure parameters from the request object used for authentication. Each entry
  # given should be a request method and it will automatically be passed to the
  # find_for_authentication method and considered in your model lookup. For instance,
  # if you set :request_keys to [:subdomain], :subdomain will be used on authentication.
  # The same considerations mentioned for authentication_keys also apply to request_keys.
  # config.request_keys = []

  # ------------------------------------------
  # 大文字小文字の区別
  # ------------------------------------------
  # 【case_insensitive_keys】
  # メールアドレスの大文字小文字を区別しない設定。
  # "User@Example.com" と "user@example.com" を同一視。
  #
  # Configure which authentication keys should be case-insensitive.
  # These keys will be downcased upon creating or modifying a user and when used
  # to authenticate or find a user. Default is :email.
  config.case_insensitive_keys = [ :email ]

  # ------------------------------------------
  # 空白除去設定
  # ------------------------------------------
  # 【strip_whitespace_keys】
  # メールアドレスの前後の空白を自動除去。
  # " user@example.com " → "user@example.com"
  #
  # Configure which authentication keys should have whitespace stripped.
  # These keys will have whitespace before and after removed upon creating or
  # modifying a user and when used to authenticate or find a user. Default is :email.
  config.strip_whitespace_keys = [ :email ]

  # Tell if authentication through request.params is enabled. True by default.
  # It can be set to an array that will enable params authentication only for the
  # given strategies, for example, `config.params_authenticatable = [:database]` will
  # enable it only for database (email + password) authentication.
  # config.params_authenticatable = true

  # Tell if authentication through HTTP Auth is enabled. False by default.
  # It can be set to an array that will enable http authentication only for the
  # given strategies, for example, `config.http_authenticatable = [:database]` will
  # enable it only for database authentication.
  # For API-only applications to support authentication "out-of-the-box", you will likely want to
  # enable this with :database unless you are using a custom strategy.
  # The supported strategies are:
  # :database      = Support basic authentication with authentication key + password
  # config.http_authenticatable = false

  # If 401 status code should be returned for AJAX requests. True by default.
  # config.http_authenticatable_on_xhr = true

  # The realm used in Http Basic Authentication. 'Application' by default.
  # config.http_authentication_realm = 'Application'

  # It will change confirmation, password recovery and other workflows
  # to behave the same regardless if the e-mail provided was right or wrong.
  # Does not affect registerable.
  # config.paranoid = true

  # ------------------------------------------
  # セッション保存設定
  # ------------------------------------------
  # 【skip_session_storage】
  # HTTP認証時はセッションに保存しない設定。
  # API利用時にセッションを使わないためのオプション。
  #
  # By default Devise will store the user in session. You can skip storage for
  # particular strategies by setting this option.
  # Notice that if you are skipping storage for all authentication paths, you
  # may want to disable generating routes to Devise's sessions controller by
  # passing skip: :sessions to `devise_for` in your config/routes.rb
  config.skip_session_storage = [ :http_auth ]

  # By default, Devise cleans up the CSRF token on authentication to
  # avoid CSRF token fixation attacks. This means that, when using AJAX
  # requests for sign in and sign up, you need to get a new CSRF token
  # from the server. You can disable this option at your own risk.
  # config.clean_up_csrf_token_on_authentication = true

  # When false, Devise will not attempt to reload routes on eager load.
  # This can reduce the time taken to boot the app but if your application
  # requires the Devise mappings to be loaded during boot time the application
  # won't boot properly.
  # config.reload_routes = true

  # ------------------------------------------
  # パスワードハッシュ強度（bcrypt）
  # ------------------------------------------
  # 【stretchesとは？】
  # パスワードハッシュの計算回数。
  # 数値が大きいほど安全だが、処理時間も増える。
  #
  # 【なぜテスト環境だけ1？】
  # テストの実行速度を上げるため。
  # 本番では12が推奨（十分なセキュリティ）。
  #
  # ==> Configuration for :database_authenticatable
  # For bcrypt, this is the cost for hashing the password and defaults to 12. If
  # using other algorithms, it sets how many times you want the password to be hashed.
  # The number of stretches used for generating the hashed password are stored
  # with the hashed password. This allows you to change the stretches without
  # invalidating existing passwords.
  #
  # Limiting the stretches to just one in testing will increase the performance of
  # your test suite dramatically. However, it is STRONGLY RECOMMENDED to not use
  # a value less than 10 in other environments. Note that, for bcrypt (the default
  # algorithm), the cost increases exponentially with the number of stretches (e.g.
  # a value of 20 is already extremely slow: approx. 60 seconds for 1 calculation).
  config.stretches = Rails.env.test? ? 1 : 12

  # Set up a pepper to generate the hashed password.
  # config.pepper = '5f50487e40fb571d0f8b94badc499986064001f496e1d364dcbbebb4c4ce6218817ef7767e160d633dedd489541cd2a112e900ed89128a7fbba36cb40f85781f'

  # Send a notification to the original email when the user's email is changed.
  # config.send_email_changed_notification = false

  # Send a notification email when the user's password is changed.
  # config.send_password_change_notification = false

  # ------------------------------------------
  # メール確認設定（Confirmable）
  # ------------------------------------------
  # 【現在の状態】
  # このアプリではメール確認機能を使用していない。
  # 将来的に有効化する場合の設定例。
  #
  # ==> Configuration for :confirmable
  # A period that the user is allowed to access the website even without
  # confirming their account. For instance, if set to 2.days, the user will be
  # able to access the website for two days without confirming their account,
  # access will be blocked just in the third day.
  # You can also set it to nil, which will allow the user to access the website
  # without confirming their account.
  # Default is 0.days, meaning the user cannot access the website without
  # confirming their account.
  # config.allow_unconfirmed_access_for = 2.days

  # A period that the user is allowed to confirm their account before their
  # token becomes invalid. For example, if set to 3.days, the user can confirm
  # their account within 3 days after the mail was sent, but on the fourth day
  # their account can't be confirmed with the token any more.
  # Default is nil, meaning there is no restriction on how long a user can take
  # before confirming their account.
  # config.confirm_within = 3.days

  # ------------------------------------------
  # メール変更時の再確認
  # ------------------------------------------
  # 【reconfirmableとは？】
  # メールアドレス変更時に新しいアドレスに確認メールを送る設定。
  # trueの場合、確認するまで元のメールアドレスが使われる。
  #
  # If true, requires any email changes to be confirmed (exactly the same way as
  # initial account confirmation) to be applied. Requires additional unconfirmed_email
  # db field (see migrations). Until confirmed, new email is stored in
  # unconfirmed_email column, and copied to email column on successful confirmation.
  config.reconfirmable = true

  # Defines which key will be used when confirming an account
  # config.confirmation_keys = [:email]

  # ------------------------------------------
  # 「ログイン状態を保持」設定（Rememberable）
  # ------------------------------------------
  # 【expire_all_remember_me_on_sign_out】
  # ログアウト時に全てのremember meトークンを無効化。
  # セキュリティのため true を推奨。
  #
  # ==> Configuration for :rememberable
  # The time the user will be remembered without asking for credentials again.
  # config.remember_for = 2.weeks

  # Invalidates all the remember me tokens when the user signs out.
  config.expire_all_remember_me_on_sign_out = true

  # If true, extends the user's remember period when remembered via cookie.
  # config.extend_remember_period = false

  # Options to be passed to the created cookie. For instance, you can set
  # secure: true in order to force SSL only cookies.
  # config.rememberable_options = {}

  # ------------------------------------------
  # パスワードバリデーション設定（Validatable）
  # ------------------------------------------
  # 【password_length】
  # パスワードの長さ制限。
  # 6文字以上、128文字以下を許可。
  #
  # 【email_regexp】
  # メールアドレスの形式チェック用正規表現。
  # シンプルなチェック（@が1つ含まれること）のみ。
  #
  # ==> Configuration for :validatable
  # Range for password length.
  config.password_length = 6..128

  # Email regex used to validate email formats. It simply asserts that
  # one (and only one) @ exists in the given string. This is mainly
  # to give user feedback and not to assert the e-mail validity.
  config.email_regexp = /\A[^@\s]+@[^@\s]+\z/

  # ==> Configuration for :timeoutable
  # The time you want to timeout the user session without activity. After this
  # time the user will be asked for credentials again. Default is 30 minutes.
  # config.timeout_in = 30.minutes

  # ==> Configuration for :lockable
  # Defines which strategy will be used to lock an account.
  # :failed_attempts = Locks an account after a number of failed attempts to sign in.
  # :none            = No lock strategy. You should handle locking by yourself.
  # config.lock_strategy = :failed_attempts

  # Defines which key will be used when locking and unlocking an account
  # config.unlock_keys = [:email]

  # Defines which strategy will be used to unlock an account.
  # :email = Sends an unlock link to the user email
  # :time  = Re-enables login after a certain amount of time (see :unlock_in below)
  # :both  = Enables both strategies
  # :none  = No unlock strategy. You should handle unlocking by yourself.
  # config.unlock_strategy = :both

  # Number of authentication tries before locking an account if lock_strategy
  # is failed attempts.
  # config.maximum_attempts = 20

  # Time interval to unlock the account if :time is enabled as unlock_strategy.
  # config.unlock_in = 1.hour

  # Warn on the last attempt before the account is locked.
  # config.last_attempt_warning = true

  # ------------------------------------------
  # パスワードリセット設定（Recoverable）
  # ------------------------------------------
  # 【reset_password_within】
  # パスワードリセットトークンの有効期限。
  # 6時間以内にリセットしないと無効になる。
  #
  # ==> Configuration for :recoverable
  #
  # Defines which key will be used when recovering the password for an account
  # config.reset_password_keys = [:email]

  # Time interval you can reset your password with a reset password key.
  # Don't put a too small interval or your users won't have the time to
  # change their passwords.
  config.reset_password_within = 6.hours

  # When set to false, does not sign a user in automatically after their password is
  # reset. Defaults to true, so a user is signed in automatically after a reset.
  # config.sign_in_after_reset_password = true

  # ==> Configuration for :encryptable
  # Allow you to use another hashing or encryption algorithm besides bcrypt (default).
  # You can use :sha1, :sha512 or algorithms from others authentication tools as
  # :clearance_sha1, :authlogic_sha512 (then you should set stretches above to 20
  # for default behavior) and :restful_authentication_sha1 (then you should set
  # stretches to 10, and copy REST_AUTH_SITE_KEY to pepper).
  #
  # Require the `devise-encryptable` gem when using anything other than bcrypt
  # config.encryptor = :sha512

  # ==> Scopes configuration
  # Turn scoped views on. Before rendering "sessions/new", it will first check for
  # "users/sessions/new". It's turned off by default because it's slower if you
  # are using only default views.
  # config.scoped_views = false

  # Configure the default scope given to Warden. By default it's the first
  # devise role declared in your routes (usually :user).
  # config.default_scope = :user

  # Set this configuration to false if you want /users/sign_out to sign out
  # only the current scope. By default, Devise signs out all scopes.
  # config.sign_out_all_scopes = true

  # ------------------------------------------
  # ナビゲーション設定
  # ------------------------------------------
  # 【navigational_formats】
  # リダイレクトを行うフォーマットを指定。
  # HTMLとTurbo Streamはリダイレクト、
  # JSONやXMLは401エラーを返す。
  #
  # ==> Navigation configuration
  # Lists the formats that should be treated as navigational. Formats like
  # :html should redirect to the sign in page when the user does not have
  # access, but formats like :xml or :json, should return 401.
  #
  # If you have any extra navigational formats, like :iphone or :mobile, you
  # should add them to the navigational formats lists.
  #
  # The "*/*" below is required to match Internet Explorer requests.
  config.navigational_formats = [ "*/*", :html, :turbo_stream ]

  # ------------------------------------------
  # ログアウト方法
  # ------------------------------------------
  # 【sign_out_via】
  # ログアウトに使用するHTTPメソッド。
  # :delete が推奨（セキュリティのため）。
  #
  # The default HTTP method used to sign out a resource. Default is :delete.
  config.sign_out_via = :delete

  # ==> OmniAuth
  # Add a new OmniAuth provider. Check the wiki for more information on setting
  # up on your models and hooks.
  # config.omniauth :github, 'APP_ID', 'APP_SECRET', scope: 'user,public_repo'

  # ==> Warden configuration
  # If you want to use other strategies, that are not supported by Devise, or
  # change the failure app, you can configure them inside the config.warden block.
  #
  # config.warden do |manager|
  #   manager.intercept_401 = false
  #   manager.default_strategies(scope: :user).unshift :some_external_strategy
  # end

  # ==> Mountable engine configurations
  # When using Devise inside an engine, let's call it `MyEngine`, and this engine
  # is mountable, there are some extra configurations to be taken into account.
  # The following options are available, assuming the engine is mounted as:
  #
  #     mount MyEngine, at: '/my_engine'
  #
  # The router that invoked `devise_for`, in the example above, would be:
  # config.router_name = :my_engine
  #
  # When using OmniAuth, Devise cannot automatically set OmniAuth path,
  # so you need to do it manually. For the users scope, it would be:
  # config.omniauth_path_prefix = '/my_engine/users/auth'

  # ------------------------------------------
  # Hotwire/Turbo対応設定
  # ------------------------------------------
  # 【error_status と redirect_status】
  # Hotwire/Turboと連携するためのHTTPステータス設定。
  #
  # 従来のRails:
  #   エラー時 → 200 OK + エラーHTML
  #   リダイレクト時 → 302 Found
  #
  # Turbo対応:
  #   エラー時 → 422 Unprocessable Entity
  #   リダイレクト時 → 303 See Other
  #
  # Turboはこのステータスコードを見て動作を決定する。
  #
  # ==> Hotwire/Turbo configuration
  # When using Devise with Hotwire/Turbo, the http status for error responses
  # and some redirects must match the following. The default in Devise for existing
  # apps is `200 OK` and `302 Found` respectively, but new apps are generated with
  # these new defaults that match Hotwire/Turbo behavior.
  # Note: These might become the new default in future versions of Devise.
  config.responder.error_status = :unprocessable_entity
  config.responder.redirect_status = :see_other

  # ==> Configuration for :registerable

  # When set to false, does not sign a user in automatically after their password is
  # changed. Defaults to true, so a user is signed in automatically after changing a password.
  # config.sign_in_after_change_password = true

  # ------------------------------------------
  # Google OAuth2 設定
  # ------------------------------------------
  # 【OmniAuthとは？】
  # 複数の認証プロバイダー（Google, Facebook, Twitter等）を
  # 統一的に扱うためのライブラリ。
  #
  # 【認証フロー】
  #
  #   1. ユーザーが「Googleでログイン」をクリック
  #      ↓
  #   2. Googleの認証ページにリダイレクト
  #      ↓
  #   3. ユーザーがGoogleで認証
  #      ↓
  #   4. コールバックURLに戻る（認証コード付き）
  #      ↓
  #   5. Deviseがトークンを取得
  #      ↓
  #   6. ユーザー情報を取得してログイン/登録
  #
  # 【必要な環境変数】
  # - GOOGLE_CLIENT_ID: Google Cloud Consoleで取得
  # - GOOGLE_CLIENT_SECRET: Google Cloud Consoleで取得
  #
  # 【取得方法】
  # 1. Google Cloud Console にアクセス
  # 2. プロジェクト作成/選択
  # 3. 「APIとサービス」→「認証情報」
  # 4. 「OAuth 2.0 クライアント ID」を作成
  # 5. 承認済みリダイレクト URI を設定
  #    例: https://mitadake.example.com/users/auth/google_oauth2/callback
  #
  # 【関連ファイル】
  # - app/controllers/users/omniauth_callbacks_controller.rb: コールバック処理
  # - app/models/user.rb: from_omniauth メソッド
  #
  config.omniauth :google_oauth2,              # Google OAuth2を使う
                ENV["GOOGLE_CLIENT_ID"],      # クライアントID（環境変数から取得）
                ENV["GOOGLE_CLIENT_SECRET"],  # クライアントシークレット（環境変数から取得）
                {
                  # ------------------------------------------
                  # スコープ設定
                  # ------------------------------------------
                  # 取得を許可する情報の範囲。
                  # email: メールアドレス
                  # profile: 名前、プロフィール画像など
                  #
                  scope: "email,profile",

                  # ------------------------------------------
                  # プロンプト設定
                  # ------------------------------------------
                  # select_account: 毎回アカウント選択画面を表示
                  # （複数のGoogleアカウントを持つユーザー向け）
                  #
                  prompt: "select_account",

                  # ------------------------------------------
                  # プロフィール画像設定
                  # ------------------------------------------
                  # square: 正方形にトリミング
                  # （アバター表示に使いやすい形式）
                  #
                  image_aspect_ratio: "square",

                  # 画像サイズ（ピクセル）
                  image_size: 50
                }
end
