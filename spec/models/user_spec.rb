require 'rails_helper'

RSpec.describe User, type: :model do
  describe "validations" do
    subject { create(:user) }

    # email validations
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }

    # name validation
    it { should validate_presence_of(:name) }

    # email format（Deviseのvalidatable）
    it "有効なメールアドレス形式を受け入れる" do
      user = build(:user, email: "test@example.com")
      expect(user).to be_valid
    end

    it "無効なメールアドレス形式を拒否する" do
      user = build(:user, email: "invalid-email")
      expect(user).not_to be_valid
    end

    # Devise password validation
    it "パスワードが6文字以上で有効" do
      user = build(:user, password: "123456")
      expect(user).to be_valid
    end

    it "パスワードが5文字以下で無効" do
      user = build(:user, password: "12345")
      expect(user).not_to be_valid
    end
  end

  describe "favorite_quote validations" do
    it "両方入力されていれば有効" do
      user = build(:user,
                   favorite_quote: "今日も頑張ろう！",
                   favorite_quote_url: "https://www.youtube.com/watch?v=abc123")
      expect(user).to be_valid
    end

    it "両方空でも有効" do
      user = build(:user, favorite_quote: nil, favorite_quote_url: nil)
      expect(user).to be_valid
    end

    it "favorite_quoteのみ入力されていると無効" do
      user = build(:user,
                   favorite_quote: "今日も頑張ろう！",
                   favorite_quote_url: nil)
      expect(user).not_to be_valid
      expect(user.errors[:base]).to include("すきな言葉と動画URLは両方入力するか、両方空にしてください")
    end

    it "favorite_quote_urlのみ入力されていると無効" do
      user = build(:user,
                   favorite_quote: nil,
                   favorite_quote_url: "https://www.youtube.com/watch?v=abc123")
      expect(user).not_to be_valid
      expect(user.errors[:base]).to include("すきな言葉と動画URLは両方入力するか、両方空にしてください")
    end

    it "favorite_quoteが50文字以内なら有効" do
      user = build(:user,
                   favorite_quote: "あ" * 50,
                   favorite_quote_url: "https://www.youtube.com/watch?v=abc123")
      expect(user).to be_valid
    end

    it "favorite_quoteが51文字以上なら無効" do
      user = build(:user,
                   favorite_quote: "あ" * 51,
                   favorite_quote_url: "https://www.youtube.com/watch?v=abc123")
      expect(user).not_to be_valid
    end

    it "有効なYouTube URL（youtube.com）を受け入れる" do
      user = build(:user,
                   favorite_quote: "テスト",
                   favorite_quote_url: "https://www.youtube.com/watch?v=abc123")
      expect(user).to be_valid
    end

    it "有効なYouTube URL（youtu.be）を受け入れる" do
      user = build(:user,
                   favorite_quote: "テスト",
                   favorite_quote_url: "https://youtu.be/abc123")
      expect(user).to be_valid
    end

    it "無効なURLを拒否する" do
      user = build(:user,
                   favorite_quote: "テスト",
                   favorite_quote_url: "https://example.com/video")
      expect(user).not_to be_valid
      expect(user.errors[:favorite_quote_url]).to include("は有効なYouTube URLを入力してください")
    end
  end

  describe "associations" do
    it { should have_many(:posts).dependent(:destroy) }
    it { should have_many(:achievements).dependent(:destroy) }
    it { should have_many(:post_entries).dependent(:destroy) }
    it { should have_many(:entry_likes).dependent(:destroy) }
  end

  describe "dependent destroy (実データ確認)" do
    it "ユーザー削除で関連レコードも削除される" do
      user = create(:user)
      post = create(:post, user: user)
      create(:achievement, user: user, post: post, achieved_at: Date.current)

      expect {
        user.destroy
      }.to change {
        [
          Post.where(user_id: user.id).count,
          Achievement.where(user_id: user.id).count
        ]
      }.from([ 1, 1 ]).to([ 0, 0 ])
    end
  end
  describe '.from_omniauth' do
    let(:auth) do
      OmniAuth::AuthHash.new(
        provider: 'google_oauth2',
        uid: '123456789',
        info: {
          email: 'test@example.com'
        }
      )
    end

    context 'すでに連携済みのユーザーの場合' do
      let!(:existing_user) do
        create(:user,
              email: 'test@example.com',
              provider: 'google_oauth2',
              uid: '123456789')
      end

      it '既存ユーザーを返す' do
        result = User.from_omniauth(auth)
        expect(result).to eq(existing_user)
      end

      it 'ユーザー数が増えない' do
        expect {
          User.from_omniauth(auth)
        }.not_to change(User, :count)
      end
    end

    context '同じメールの既存ユーザーがいる場合' do
      let!(:existing_user) do
        create(:user, email: 'test@example.com')
      end

      it '既存ユーザーにproviderとuidを追加する' do
        result = User.from_omniauth(auth)
        expect(result.provider).to eq('google_oauth2')
        expect(result.uid).to eq('123456789')
      end

      it 'ユーザー数が増えない' do
        expect {
          User.from_omniauth(auth)
        }.not_to change(User, :count)
      end
    end

    context '新規ユーザーの場合' do
      it '新しいユーザーを作成する' do
        expect {
          User.from_omniauth(auth)
        }.to change(User, :count).by(1)
      end

      it '正しい属性でユーザーが作成される' do
        user = User.from_omniauth(auth)
        expect(user.email).to eq('test@example.com')
        expect(user.provider).to eq('google_oauth2')
        expect(user.uid).to eq('123456789')
        expect(user.password).to be_present
      end

      it 'パスワードが自動生成される' do
        user = User.from_omniauth(auth)
        expect(user.encrypted_password).to be_present
      end
    end

    context '名前がnilのauthデータの場合' do
      let(:auth_without_name) do
        OmniAuth::AuthHash.new(
          provider: 'google_oauth2',
          uid: '987654321',
          info: {
            email: 'noname@example.com',
            name: nil
          }
        )
      end

      it '名前がnilの場合はメールアドレスが名前として設定される' do
        # 実際の挙動: auth.info.nameがnilの場合、メールが名前になる
        user = User.from_omniauth(auth_without_name)
        expect(user).to be_persisted
        expect(user.name).to eq('noname@example.com')
      end
    end

    context '既存ユーザーの名前が空の場合' do
      let(:auth_with_name) do
        OmniAuth::AuthHash.new(
          provider: 'google_oauth2',
          uid: '111222333',
          info: {
            email: 'existing@example.com',
            name: 'Google Name'
          }
        )
      end

      let!(:existing_user) do
        create(:user, email: 'existing@example.com', name: 'Original Name')
      end

      it 'Googleの名前で更新しない（既存名がある場合）' do
        result = User.from_omniauth(auth_with_name)
        expect(result.name).to eq('Original Name')
      end
    end
  end

end
