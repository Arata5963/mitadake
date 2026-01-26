# config/routes.rb
# ==========================================
# ルーティング設定（URLとコントローラーの対応表）
# ==========================================
#
# 【このファイルの役割】
# URLパターンとコントローラーのアクションを紐付ける。
# ユーザーがアクセスしたURLに対して、どの処理を実行するか決定。
#
# 【ルーティングの基本】
#   get "/posts" → PostsController#index を実行
#   HTTPメソッド "パス" → コントローラー#アクション
#
# 【HTTPメソッドの意味】
#   GET    = データの取得（ページ表示）
#   POST   = データの作成
#   PATCH  = データの更新
#   DELETE = データの削除
#
# 【ルートの確認方法】
#   docker compose exec web rails routes
#
# 【URL生成ヘルパー】
#   posts_path     → "/posts"
#   post_path(@p)  → "/posts/1"
#   root_path      → "/"
#
Rails.application.routes.draw do
  # ==========================================
  # Devise（認証）ルート
  # ==========================================
  # 以下のルートが自動生成される:
  #   /users/sign_in    - ログインページ
  #   /users/sign_out   - ログアウト
  #   /users/sign_up    - 新規登録
  #   /users/password   - パスワードリセット
  #   /users/auth/google_oauth2 - Googleログイン
  devise_for :users, controllers: {
    omniauth_callbacks: "users/omniauth_callbacks"  # OAuth認証のコールバック処理
  }

  # ==========================================
  # 開発環境専用ツール
  # ==========================================
  # 開発環境でメールをブラウザで確認できるようにする
  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"  # メール確認UI
  end

  # ==========================================
  # ヘルスチェック
  # ==========================================
  # サーバーが正常に動作しているか確認するエンドポイント
  # 本番環境のロードバランサーなどが使用
  get "up" => "rails/health#show", as: :rails_health_check

  # ==========================================
  # ルートURL（トップページ）
  # ==========================================
  # 未ログイン → LP表示
  # ログイン済み → 投稿一覧へリダイレクト
  root "pages#home"

  # ==========================================
  # ユーザー関連ルート
  # ==========================================
  # マイページ（自分のプロフィール）
  get :mypage, to: "users#show"         # GET /mypage → UsersController#show
  get :edit_profile, to: "users#edit"   # GET /edit_profile → UsersController#edit
  patch :mypage, to: "users#update"     # PATCH /mypage → UsersController#update
  # アクション一覧ページ
  get "mypage/pending_actions", to: "users#pending_actions", as: :pending_actions   # 挑戦中のアクション一覧
  get "mypage/achieved_actions", to: "users#achieved_actions", as: :achieved_actions # 達成したアクション一覧
  # 他ユーザーのプロフィール（:id が動的に変わる）
  get "users/:id", to: "users#show", as: :user_profile  # GET /users/123

  # ==========================================
  # 投稿（Post）リソース
  # ==========================================
  # resources = RESTfulなルートを一括生成
  # except: [:create] → createだけ生成しない（find_or_createを使うため）
  #
  # 自動生成されるルート:
  #   GET    /posts          → index（一覧）
  #   GET    /posts/new      → new（新規作成フォーム）
  #   GET    /posts/:id      → show（詳細表示）
  #   GET    /posts/:id/edit → edit（編集フォーム）
  #   PATCH  /posts/:id      → update（更新処理）
  #   DELETE /posts/:id      → destroy（削除処理）
  resources :posts, except: [ :create ] do
    # collection = /posts/○○ のカスタムルート（IDなし）
    collection do
      get :autocomplete           # GET /posts/autocomplete - 検索オートコンプリート
      get :youtube_search         # GET /posts/youtube_search - YouTube検索API
      get :search_posts           # GET /posts/search_posts - 投稿検索
      post :find_or_create        # POST /posts/find_or_create - 動画を検索or作成
      post :create_with_action    # POST /posts/create_with_action - 動画+アクションプランを同時作成
      post :convert_to_youtube_title  # POST /posts/convert_to_youtube_title - タイトル変換
      post :suggest_action_plans  # POST /posts/suggest_action_plans - AI提案
      get :recent                 # GET /posts/recent - 最近の投稿
    end

    member do
      patch :update_with_action   # PATCH /posts/:id/update_with_action - 動画+アクションプランを同時更新
    end

    # ネストしたリソース（投稿に紐づくエントリー）
    # /posts/:post_id/post_entries/...
    resources :post_entries, only: [ :create, :edit, :update, :destroy ] do
      # member = /posts/:post_id/post_entries/:id/○○ のカスタムルート（IDあり）
      member do
        patch :achieve            # PATCH .../achieve - 達成マーク
        post :toggle_like         # POST .../toggle_like - いいね切り替え
        get :show_achievement     # GET .../show_achievement - 達成モーダル表示
        patch :update_reflection  # PATCH .../update_reflection - 振り返り更新
      end
    end
  end

  # ==========================================
  # 静的ページ
  # ==========================================
  get :terms, to: "pages#terms"      # GET /terms → 利用規約
  get :privacy, to: "pages#privacy"  # GET /privacy → プライバシーポリシー


  # ==========================================
  # API エンドポイント
  # ==========================================
  # namespace = プレフィックスを追加（/api/...）
  # コントローラーは Api:: モジュール内に配置
  namespace :api do
    # POST /api/presigned_urls → Api::PresignedUrlsController#create
    # S3への直接アップロード用の署名付きURLを生成
    resources :presigned_urls, only: [ :create ]
  end
end
