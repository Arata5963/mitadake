require 'rails_helper'

RSpec.describe Achievement, type: :model do
  describe "validations" do
    subject { create(:achievement) }

    # タスク型：1投稿につき1ユーザー1回のみ
    it do
      should validate_uniqueness_of(:post_id)
        .scoped_to(:user_id)
        .with_message("既に達成済みです")
    end

    it { should validate_presence_of(:achieved_at) }

    describe "二重達成の防止" do
      let(:user) { create(:user) }
      let(:post) { create(:post) }
      let!(:existing_achievement) { create(:achievement, user: user, post: post) }

      it "同じユーザーが同じ投稿を二重達成できない" do
        duplicate = build(:achievement, user: user, post: post)
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:post_id]).to include("既に達成済みです")
      end

      it "異なるユーザーは同じ投稿を達成できる" do
        other_user = create(:user)
        other_achievement = build(:achievement, user: other_user, post: post)
        expect(other_achievement).to be_valid
      end

      it "同じユーザーが異なる投稿を達成できる" do
        other_post = create(:post)
        other_achievement = build(:achievement, user: user, post: other_post)
        expect(other_achievement).to be_valid
      end
    end
  end

  describe "associations" do
    it { should belong_to(:user) }
    it { should belong_to(:post) }
  end

  describe "ビジネスロジック" do
    describe "達成の作成" do
      let(:user) { create(:user) }
      let(:post) { create(:post, user: user) }

      it "achieved_atが自動設定される（ファクトリ経由）" do
        achievement = create(:achievement, user: user, post: post)
        expect(achievement.achieved_at).to be_present
      end

      it "achieved_atを明示的に指定できる" do
        specific_date = Date.new(2024, 1, 15)
        achievement = create(:achievement, user: user, post: post, achieved_at: specific_date)
        expect(achievement.achieved_at).to eq(specific_date)
      end

      it "user_idがないと保存できない" do
        achievement = build(:achievement, user: nil, post: post)
        expect(achievement).not_to be_valid
      end

      it "post_idがないと保存できない" do
        achievement = build(:achievement, user: user, post: nil)
        expect(achievement).not_to be_valid
      end
    end

    describe "特定ユーザーの達成" do
      let(:user) { create(:user) }
      let(:other_user) { create(:user) }

      before do
        create_list(:achievement, 3, user: user)
        create_list(:achievement, 2, user: other_user)
      end

      it "ユーザーごとの達成を取得できる" do
        expect(Achievement.where(user: user).count).to eq(3)
        expect(Achievement.where(user: other_user).count).to eq(2)
      end
    end
  end
end
