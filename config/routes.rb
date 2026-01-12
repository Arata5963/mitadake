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

  # 通知
  resources :notifications, only: [ :index ] do
    post :mark_as_read, on: :member
    post :mark_all_as_read, on: :collection
  end

  resources :posts, except: [ :new, :create ] do
    collection do
      get :autocomplete
      get :youtube_search
      post :find_or_create
      get :trending
      get :ranking
      get :channels
      get :user_ranking
      get :recent
    end
    member do
      post :summarize
      get :youtube_comments
      post :discover_comments
      post :suggest_action_plans
    end
    resources :achievements, only: [ :create, :destroy ]
    resources :cheers, only: [ :create, :destroy ]
    resources :post_entries, only: [ :create, :edit, :update, :destroy ] do
      patch :achieve, on: :member
    end
  end

  # YouTubeコメントブックマーク
  resources :youtube_comments, only: [] do
    resource :bookmark, controller: :comment_bookmarks, only: [:create, :destroy]
  end

  get :terms, to: "pages#terms"
  get :privacy, to: "pages#privacy"
end
