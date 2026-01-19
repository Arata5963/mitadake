require "sidekiq/web"
require "sidekiq-scheduler/web"

Rails.application.routes.draw do
  devise_for :users, controllers: {
    omniauth_callbacks: "users/omniauth_callbacks"
  }

  # 開発環境でメールをブラウザで確認できるようにする
  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
    mount Sidekiq::Web, at: "/sidekiq"  # Sidekiq Web UI
    get "design/countdown", to: "pages#countdown_design"
    get "design/action-plan", to: "pages#action_plan_design"
    get "design/achieved-videos", to: "pages#achieved_videos_design"
    get "design/new-post", to: "pages#new_post_design"
    get "design/landing", to: "pages#landing_design"
    get "design/landing-a", to: "pages#landing_a_design"
    get "design/landing-b", to: "pages#landing_b_design"
    get "design/landing-c", to: "pages#landing_c_design"
  end

  get "up" => "rails/health#show", as: :rails_health_check

  root "posts#index"

  get :home, to: "home#index"

  get :mypage, to: "users#show"
  get :edit_profile, to: "users#edit"
  patch :mypage, to: "users#update"
  get "users/:id", to: "users#show", as: :user_profile

  get :bookshelf, to: "bookshelves#show"
  get "users/:id/bookshelf", to: "bookshelves#show", as: :user_bookshelf

  # 統計・分析
  get :stats, to: "stats#show"

  resources :posts, except: [ :create ] do
    collection do
      get :autocomplete
      get :youtube_search
      get :search_posts
      post :find_or_create
      post :create_with_action
      post :convert_to_youtube_title
      post :suggest_action_plans
      get :trending
      get :channels
      get :recent
    end
    member do
      post :summarize
      get :youtube_comments
      post :discover_comments
    end
    resources :achievements, only: [ :create, :destroy ]
    resources :cheers, only: [ :create, :destroy ]
    resources :post_entries, only: [ :create, :edit, :update, :destroy ] do
      member do
        patch :achieve
        post :toggle_flame
        get :show_achievement
        patch :update_reflection
      end
      resources :entry_flames, only: [ :create, :destroy ]
    end
  end

  # YouTubeコメントブックマーク
  resources :youtube_comments, only: [] do
    resource :bookmark, controller: :comment_bookmarks, only: [:create, :destroy]
  end

  get :terms, to: "pages#terms"
  get :privacy, to: "pages#privacy"
end
