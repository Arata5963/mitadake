# OmniAuth コールバックのリクエストテスト
# Google OAuth2認証の成功・失敗パターンを検証

require 'rails_helper'

RSpec.describe 'OmniauthCallbacks', type: :request do
  before(:all) do
    OmniAuth.config.test_mode = true
  end

  after(:all) do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:google_oauth2] = nil
  end

  after(:each) do
    OmniAuth.config.mock_auth[:google_oauth2] = nil
  end

  describe 'GET /users/auth/google_oauth2/callback' do
    context '正常系: 新規ユーザーの場合' do
      it 'Google認証情報から新規ユーザーを作成してログインできる' do
        # モックOAuth認証情報を設定
        OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
          provider: 'google_oauth2',
          uid: '123456789',
          info: {
            email: 'newuser@example.com',
            name: 'New OAuth User'
          },
          credentials: {
            token: 'mock_token',
            refresh_token: 'mock_refresh_token',
            expires_at: Time.current.to_i + 3600
          }
        })

        expect {
          get '/users/auth/google_oauth2/callback'
        }.to change(User, :count).by(1)

        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(root_path)               # root→posts_pathへ再リダイレクト

        # 作成されたユーザーの確認
        user = User.last
        expect(user.email).to eq('newuser@example.com')
        expect(user.provider).to eq('google_oauth2')
        expect(user.uid).to eq('123456789')

        # ログイン状態の確認（投稿一覧ページへリダイレクト）
        follow_redirect!                                         # root_path → posts_path
        follow_redirect!                                         # posts_pathへ
        expect(response).to have_http_status(:ok)
      end
    end

    context '正常系: 既存ユーザーの場合' do
      let!(:existing_user) do
        User.create!(
          name: 'Existing User',
          email: 'existing@example.com',
          provider: 'google_oauth2',
          uid: '987654321',
          password: Devise.friendly_token[0, 20]
        )
      end

      it '既存ユーザーでログインできる' do
        OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
          provider: 'google_oauth2',
          uid: '987654321',
          info: {
            email: 'existing@example.com',
            name: 'Existing User'
          }
        })

        expect {
          get '/users/auth/google_oauth2/callback'
        }.not_to change(User, :count)

        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(root_path)
      end
    end

    context '異常系: 認証情報が取得できない場合（invalid_credentials）' do
      it 'failureアクションを経由してトップページにリダイレクトする' do
        # OmniAuthのモックをinvalid_credentialsに設定して、認証失敗をシミュレート
        OmniAuth.config.mock_auth[:google_oauth2] = :invalid_credentials

        get '/users/auth/google_oauth2/callback'

        # invalid_credentialsの場合、failureアクションを経由してroot_pathにリダイレクト
        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(root_path)

        # フラッシュメッセージが設定される
        expect(flash[:alert]).to include('Google認証に失敗しました')
      end
    end

    context '異常系: ユーザー作成に失敗した場合' do
      it 'エラーメッセージを表示してログインページにリダイレクト' do
        # 無効なメールアドレスでユーザー作成を失敗させる
        OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
          provider: 'google_oauth2',
          uid: 'invalid_uid',
          info: {
            email: '', # 空のメールアドレス
            name: 'Invalid User'
          }
        })

        # User.from_omniauthがエラーを起こすことを想定
        allow(User).to receive(:from_omniauth).and_raise(StandardError.new('Database error'))

        get '/users/auth/google_oauth2/callback'

        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(new_user_session_path)

        follow_redirect!
        expect(response.body).to include('ユーザー作成に失敗')
      end
    end

    context '異常系: ユーザーが保存されない場合' do
      it 'バリデーションエラーメッセージを表示' do
        # from_omniauthで作成されるが、保存されないユーザーをモック
        unsaved_user = User.new(
          email: 'test@example.com',
          provider: 'google_oauth2',
          uid: 'test_uid'
        )
        unsaved_user.errors.add(:base, 'テスト用エラー')

        allow(User).to receive(:from_omniauth).and_return(unsaved_user)
        allow(unsaved_user).to receive(:persisted?).and_return(false)

        OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
          provider: 'google_oauth2',
          uid: 'test_uid',
          info: { email: 'test@example.com', name: 'Test User' }
        })

        get '/users/auth/google_oauth2/callback'

        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(new_user_session_path)

        follow_redirect!
        expect(response.body).to include('Google認証に失敗しました')
      end
    end
  end
end
