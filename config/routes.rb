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

  get :mypage, to: "users#show"
  get :edit_profile, to: "users#edit"
  patch :mypage, to: "users#update"
  get "users/:id", to: "users#show", as: :user_profile

  resources :posts, except: [ :create ] do
    collection do
      get :autocomplete
      get :youtube_search
      get :search_posts
      post :find_or_create
      post :create_with_action
      post :convert_to_youtube_title
      post :suggest_action_plans
      get :recent
    end
    resources :post_entries, only: [ :create, :edit, :update, :destroy ] do
      member do
        patch :achieve
        post :toggle_like
        get :show_achievement
        patch :update_reflection
      end
    end
  end

  get :terms, to: "pages#terms"
  get :privacy, to: "pages#privacy"

  # API
  namespace :api do
    resources :presigned_urls, only: [:create]
  end
end
