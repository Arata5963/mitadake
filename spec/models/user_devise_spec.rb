# spec/models/user_devise_spec.rb
# ==========================================
# User モデルのDevise機能テスト
# ==========================================
#
# 【このファイルの役割】
# Deviseが提供する認証機能が正しく設定されているかを検証する。
# user_spec.rb を補完するテスト。
#
# 【テストの実行方法】
#   docker compose exec web rspec spec/models/user_devise_spec.rb
#
# 【テスト対象】
# - Deviseモジュール（database_authenticatable, registerable等）
# - OmniAuth（Google OAuth2）設定
# - メールバリデーション（フォーマット、重複）
# - パスワードバリデーション（長さ、確認）
# - アバターアップローダー設定
# - 依存削除（ユーザー削除時の連鎖削除）
#
# 【Deviseモジュール一覧】
# - database_authenticatable: パスワード認証
# - registerable: ユーザー登録
# - recoverable: パスワードリセット
# - rememberable: ログイン状態保持
# - validatable: メール・パスワードバリデーション
# - omniauthable: OAuth認証（Google）
#
require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'Devise modules' do
    it 'database_authenticatableが有効である' do
      expect(User.devise_modules).to include(:database_authenticatable)
    end

    it 'registerableが有効である' do
      expect(User.devise_modules).to include(:registerable)
    end

    it 'recoverableが有効である' do
      expect(User.devise_modules).to include(:recoverable)
    end

    it 'rememberableが有効である' do
      expect(User.devise_modules).to include(:rememberable)
    end

    it 'validatableが有効である' do
      expect(User.devise_modules).to include(:validatable)
    end

    it 'omniauthableが有効である' do
      expect(User.devise_modules).to include(:omniauthable)
    end

    it 'OmniAuthプロバイダーにgoogle_oauth2が設定されている' do
      expect(User.omniauth_providers).to include(:google_oauth2)
    end
  end

  describe 'mount_uploader' do
    let(:user) { create(:user) }

    it 'avatarにImageUploaderがマウントされている' do
      expect(user.avatar).to be_a(ImageUploader)
    end

    it 'アバターをアップロードできる', skip: 'ImageMagickが必要なためCI環境ではスキップ' do
      user.avatar = fixture_file_upload('spec/fixtures/files/sample_avatar.jpg', 'image/jpeg')
      expect(user.save).to be true
      expect(user.avatar.present?).to be true
    end

    it 'アバターを削除できる', skip: 'ImageMagickが必要なためCI環境ではスキップ' do
      user.avatar = fixture_file_upload('spec/fixtures/files/sample_avatar.jpg', 'image/jpeg')
      user.save

      user.remove_avatar!
      user.save

      expect(user.avatar.present?).to be false
    end
  end

  describe 'email validation' do
    context '有効なメールアドレス' do
      it '標準的なメールアドレスが有効' do
        user = build(:user, email: 'test@example.com')
        expect(user).to be_valid
      end

      it 'サブドメイン付きメールアドレスが有効' do
        user = build(:user, email: 'user@mail.example.com')
        expect(user).to be_valid
      end

      it 'プラス記号を含むメールアドレスが有効' do
        user = build(:user, email: 'user+tag@example.com')
        expect(user).to be_valid
      end
    end

    context '無効なメールアドレス' do
      it '空のメールアドレスは無効' do
        user = build(:user, email: '')
        expect(user).not_to be_valid
        expect(user.errors[:email]).to be_present
      end

      it 'nilのメールアドレスは無効' do
        user = build(:user, email: nil)
        expect(user).not_to be_valid
        expect(user.errors[:email]).to be_present
      end

      it '@がないメールアドレスは無効' do
        user = build(:user, email: 'invalid-email')
        expect(user).not_to be_valid
        expect(user.errors[:email]).to be_present
      end

      it 'ドメインがないメールアドレスは無効' do
        user = build(:user, email: 'user@')
        expect(user).not_to be_valid
        expect(user.errors[:email]).to be_present
      end
    end

    context '重複チェック' do
      let!(:existing_user) { create(:user, email: 'test@example.com') }

      it '大文字小文字を区別せず重複をチェック' do
        user = build(:user, email: 'TEST@EXAMPLE.COM')
        expect(user).not_to be_valid
        expect(user.errors[:email]).to be_present
      end

      it '異なるメールアドレスなら作成できる' do
        user = build(:user, email: 'another@example.com')
        expect(user).to be_valid
      end
    end
  end

  describe 'password validation (詳細)' do
    context 'パスワードの長さ' do
      it '5文字以下は無効' do
        user = build(:user, password: '12345', password_confirmation: '12345')
        expect(user).not_to be_valid
        expect(user.errors[:password]).to be_present
      end

      it '6文字以上は有効' do
        user = build(:user, password: '123456', password_confirmation: '123456')
        expect(user).to be_valid
      end

      it '128文字は有効' do
        long_password = 'a' * 128
        user = build(:user, password: long_password, password_confirmation: long_password)
        expect(user).to be_valid
      end
    end

    context 'パスワード確認' do
      it 'パスワードとパスワード確認が一致しない場合は無効' do
        user = build(:user, password: 'password123', password_confirmation: 'different123')
        expect(user).not_to be_valid
        expect(user.errors[:password_confirmation]).to be_present
      end

      it 'パスワードとパスワード確認が一致する場合は有効' do
        user = build(:user, password: 'password123', password_confirmation: 'password123')
        expect(user).to be_valid
      end
    end

    context '既存ユーザーの更新' do
      let(:user) { create(:user, password: 'original123') }

      it 'パスワードを変更せずに他の属性を更新できる' do
        expect {
          user.update(email: 'newemail@example.com')
        }.to change { user.email }.to('newemail@example.com')
      end

      it 'パスワードを変更できる' do
        user.password = 'newpassword123'
        user.password_confirmation = 'newpassword123'
        expect(user.save).to be true

        # 新しいパスワードで認証できる
        expect(user.valid_password?('newpassword123')).to be true
      end
    end
  end

  describe 'OmniAuth provider/uid' do
    it 'providerとuidを保存できる' do
      user = create(:user, provider: 'google_oauth2', uid: '123456')
      expect(user.provider).to eq('google_oauth2')
      expect(user.uid).to eq('123456')
    end

    it 'providerとuidは任意項目である' do
      user = build(:user, provider: nil, uid: nil)
      expect(user).to be_valid
    end
  end

  describe 'associations cascade' do
    let(:user) { create(:user) }

    before do
      post = create(:post, user: user)
      create(:post_entry, user: user, post: post, deadline: 1.week.from_now)
    end

    it 'ユーザー削除時に関連する全てのレコードが削除される' do
      expect {
        user.destroy
      }.to change { User.count }.by(-1)
        .and change { Post.count }.by(-1)
        .and change { PostEntry.count }.by(-1)
    end
  end
end
