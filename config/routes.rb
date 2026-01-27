# ルーティング設定
# URLパターンとコントローラーのアクションを紐付け

Rails.application.routes.draw do
  # Devise（認証）ルート
  devise_for :users, controllers: {
    omniauth_callbacks: "users/omniauth_callbacks"             # OAuth認証のコールバック処理
  }

  # 開発環境専用ツール
  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"        # メール確認UI
  end

  # ヘルスチェック
  get "up" => "rails/health#show", as: :rails_health_check    # ロードバランサー用

  # ルートURL
  root "pages#home"                                            # 未ログイン→LP, ログイン済み→投稿一覧

  # ユーザー関連
  get :mypage, to: "users#show"                                # マイページ
  get :edit_profile, to: "users#edit"                          # プロフィール編集
  patch :mypage, to: "users#update"                            # プロフィール更新
  get "mypage/pending_actions", to: "users#pending_actions", as: :pending_actions   # 挑戦中アクション一覧
  get "mypage/achieved_actions", to: "users#achieved_actions", as: :achieved_actions # 達成アクション一覧
  get "users/:id", to: "users#show", as: :user_profile         # 他ユーザーのプロフィール

  # 投稿（Post）リソース
  resources :posts, except: [ :create ] do
    collection do
      get :autocomplete                                        # 検索オートコンプリート
      get :youtube_search                                      # YouTube検索API
      get :search_posts                                        # 投稿検索
      post :find_or_create                                     # 動画を検索or作成
      post :create_with_action                                 # 動画+アクションプラン同時作成
      post :convert_to_youtube_title                           # タイトル変換
      post :suggest_action_plans                               # AI提案
      get :recent                                              # 最近の投稿
    end

    member do
      patch :update_with_action                                # 動画+アクションプラン同時更新
    end

    # ネストしたエントリーリソース
    resources :post_entries, only: [ :create, :edit, :update, :destroy ] do
      member do
        patch :achieve                                         # 達成マーク
        post :toggle_like                                      # いいね切り替え
        get :show_achievement                                  # 達成モーダル表示
        patch :update_reflection                               # 振り返り更新
      end
    end
  end

  # 静的ページ
  get :terms, to: "pages#terms"                                # 利用規約
  get :privacy, to: "pages#privacy"                            # プライバシーポリシー

  # API
  namespace :api do
    resources :presigned_urls, only: [ :create ]               # S3署名付きURL生成
  end
end
