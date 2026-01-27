# User モデルのテスト
# バリデーション、アソシエーション、OAuth、ランキング機能を検証

require 'rails_helper'

RSpec.describe User, type: :model do
  describe "validations" do
    subject { create(:user) }

    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
    it { should validate_presence_of(:name) }

    it "有効なメールアドレス形式を受け入れる" do
      user = build(:user, email: "test@example.com")
      expect(user).to be_valid
    end

    it "無効なメールアドレス形式を拒否する" do
      user = build(:user, email: "invalid-email")
      expect(user).not_to be_valid
    end

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
    it { should have_many(:post_entries).dependent(:destroy) }
    it { should have_many(:entry_likes).dependent(:destroy) }
  end

  describe "dependent destroy (実データ確認)" do
    it "ユーザー削除で関連レコードも削除される" do
      user = create(:user)
      post = create(:post, user: user)
      create(:post_entry, user: user, post: post, deadline: 1.week.from_now)

      expect {
        user.destroy
      }.to change {
        [
          Post.where(user_id: user.id).count,
          PostEntry.where(user_id: user.id).count
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

  describe '.by_achieved_count' do
    let!(:user1) { create(:user) }
    let!(:user2) { create(:user) }
    let!(:user3) { create(:user) }
    let!(:post) { create(:post, user: user1) }

    before do
      3.times do
        entry = create(:post_entry, post: post, user: user1)
        entry.update!(achieved_at: Time.current)
      end
      entry = create(:post_entry, post: post, user: user2)
      entry.update!(achieved_at: Time.current)
    end

    context '全期間（デフォルト）' do
      it '達成数の多い順にユーザーを返す' do
        result = User.by_achieved_count(limit: 10)
        expect(result.first).to eq(user1)
        expect(result.second).to eq(user2)
      end

      it '指定した件数に制限される' do
        result = User.by_achieved_count(limit: 1)
        expect(result.length).to eq(1)
      end

      it 'achieved_countが含まれる' do
        result = User.by_achieved_count(limit: 10)
        expect(result.first.achieved_count).to eq(3)
      end
    end

    context '期間指定（today）' do
      before do
        entry = create(:post_entry, post: post, user: user3)
        entry.update!(achieved_at: 2.days.ago)
      end

      it '本日の達成のみカウントする' do
        result = User.by_achieved_count(limit: 10, period: :today)
        user_ids = result.map(&:id)
        expect(user_ids).to include(user1.id)
        expect(user_ids).to include(user2.id)
      end
    end

    context '期間指定（week）' do
      it '今週の達成をカウントする' do
        result = User.by_achieved_count(limit: 10, period: :week)
        expect(result).to be_present
      end
    end

    context '期間指定（month）' do
      it '今月の達成をカウントする' do
        result = User.by_achieved_count(limit: 10, period: :month)
        expect(result).to be_present
      end
    end
  end

  describe '#current_action_plan' do
    let(:user) { create(:user) }
    let(:post) { create(:post, user: user) }

    context '未達成のアクションプランがある場合' do
      let!(:entry) { create(:post_entry, post: post, user: user, achieved_at: nil) }

      it '未達成のアクションプランを返す' do
        expect(user.current_action_plan).to eq(entry)
      end
    end

    context '全て達成済みの場合' do
      let!(:entry) { create(:post_entry, post: post, user: user, achieved_at: Time.current) }

      it 'nilを返す' do
        expect(user.current_action_plan).to be_nil
      end
    end

    context 'アクションプランがない場合' do
      it 'nilを返す' do
        expect(user.current_action_plan).to be_nil
      end
    end
  end

  describe '#current_video' do
    let(:user) { create(:user) }
    let(:post) { create(:post, user: user) }

    context '未達成のアクションプランがある場合' do
      let!(:entry) { create(:post_entry, post: post, user: user, achieved_at: nil) }

      it '関連する動画を返す' do
        expect(user.current_video).to eq(post)
      end
    end

    context '未達成のアクションプランがない場合' do
      it 'nilを返す' do
        expect(user.current_video).to be_nil
      end
    end
  end
end
