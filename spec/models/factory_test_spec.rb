# spec/models/factory_test_spec.rb
require 'rails_helper'

RSpec.describe "Factory の動作確認", type: :model do
  describe "User Factory" do
    it "基本的な User を作成できる" do
      user = create(:user)
      expect(user).to be_persisted
      expect(user.email).to be_present
    end

    it "複数の User を作成するとメールアドレスが重複しない" do
      user1 = create(:user)
      user2 = create(:user)
      expect(user1.email).not_to eq(user2.email)
    end
  end

  describe "Post Factory" do
    it "基本的な Post を作成できる" do
      post = create(:post)
      expect(post).to be_persisted
      expect(post.action_plan).to be_present
    end

    it "ユーザー付きで作成できる" do
      post = create(:post, :with_user)
      expect(post).to be_persisted
      expect(post.user).to be_present
    end
  end

  describe "Achievement Factory" do
    it "基本的な Achievement を作成できる" do
      achievement = create(:achievement)
      expect(achievement).to be_persisted
      expect(achievement.user).to be_present
      expect(achievement.post).to be_present
      expect(achievement.achieved_at).to eq(Date.current)
    end
  end

  describe "PostEntry Factory" do
    it "基本的な PostEntry を作成できる" do
      entry = create(:post_entry, deadline: 1.week.from_now)
      expect(entry).to be_persisted
      expect(entry.content).to be_present
      expect(entry.user).to be_present
      expect(entry.post).to be_present
    end
  end
end
