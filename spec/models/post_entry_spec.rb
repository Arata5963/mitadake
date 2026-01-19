# spec/models/post_entry_spec.rb
require 'rails_helper'

RSpec.describe PostEntry, type: :model do
  describe 'associations' do
    it { should belong_to(:post) }
    it { should belong_to(:user) }
    it { should have_many(:entry_likes).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:content) }

    describe 'one_incomplete_action_per_user' do
      let(:user) { create(:user) }
      let(:post1) { create(:post) }
      let(:post2) { create(:post) }

      context 'when user has no unachieved entries' do
        it 'allows creating a new entry' do
          entry = build(:post_entry, post: post1, user: user)
          expect(entry).to be_valid
        end
      end

      context 'when user has an unachieved entry' do
        before do
          create(:post_entry, post: post1, user: user, achieved_at: nil)
        end

        it 'rejects creating another entry on the same post' do
          entry = build(:post_entry, post: post1, user: user)
          expect(entry).not_to be_valid
          expect(entry.errors[:base]).to include("未達成のアクションプランがあります。達成してから新しいプランを投稿してください")
        end

        it 'rejects creating another entry on a different post' do
          entry = build(:post_entry, post: post2, user: user)
          expect(entry).not_to be_valid
          expect(entry.errors[:base]).to include("未達成のアクションプランがあります。達成してから新しいプランを投稿してください")
        end
      end

      context 'when user has only achieved entries' do
        before do
          create(:post_entry, :achieved, post: post1, user: user)
        end

        it 'allows creating a new entry on a different post' do
          entry = build(:post_entry, post: post2, user: user)
          expect(entry).to be_valid
        end
      end

      it 'allows different users to have unachieved entries' do
        user2 = create(:user)
        create(:post_entry, post: post1, user: user, achieved_at: nil)
        entry = build(:post_entry, post: post1, user: user2)
        expect(entry).to be_valid
      end
    end
  end

  describe 'scopes' do
    # 各テストで別ユーザーを使用してバリデーションを回避
    describe '.recent' do
      it 'returns entries in descending order of created_at' do
        user1 = create(:user)
        user2 = create(:user)
        old_entry = create(:post_entry, user: user1, created_at: 1.day.ago)
        new_entry = create(:post_entry, user: user2, created_at: Time.current)

        expect(PostEntry.recent.first).to eq(new_entry)
      end
    end

    describe '.not_achieved' do
      it 'returns entries without achieved_at' do
        user1 = create(:user)
        user2 = create(:user)
        not_achieved = create(:post_entry, user: user1)
        achieved = create(:post_entry, :achieved, user: user2)

        expect(PostEntry.not_achieved).to include(not_achieved)
        expect(PostEntry.not_achieved).not_to include(achieved)
      end
    end

    describe '.achieved' do
      it 'returns entries with achieved_at' do
        user1 = create(:user)
        user2 = create(:user)
        not_achieved = create(:post_entry, user: user1)
        achieved = create(:post_entry, :achieved, user: user2)

        expect(PostEntry.achieved).to include(achieved)
        expect(PostEntry.achieved).not_to include(not_achieved)
      end
    end

    describe '.expired' do
      it 'returns unachieved entries past deadline' do
        user1 = create(:user)
        user2 = create(:user)
        user3 = create(:user)
        expired = create(:post_entry, :overdue, user: user1)
        not_expired = create(:post_entry, user: user2)
        achieved_expired = create(:post_entry, :achieved, :overdue, user: user3)

        expect(PostEntry.expired).to include(expired)
        expect(PostEntry.expired).not_to include(not_expired)
        expect(PostEntry.expired).not_to include(achieved_expired)
      end
    end
  end

  describe '#achieved?' do
    it 'returns true when achieved_at is present' do
      entry = build(:post_entry, :achieved)
      expect(entry.achieved?).to be true
    end

    it 'returns false when achieved_at is nil' do
      entry = build(:post_entry)
      expect(entry.achieved?).to be false
    end
  end

  describe '#achieve!' do
    let(:user) { create(:user) }
    let(:entry) { create(:post_entry, user: user) }

    it 'sets achieved_at when not achieved' do
      expect { entry.achieve! }.to change { entry.achieved_at }.from(nil)
    end

    it 'clears achieved_at when already achieved' do
      entry.update!(achieved_at: Time.current)
      expect(entry.achieved_at).to be_present
      entry.achieve!
      expect(entry.achieved_at).to be_nil
    end
  end

  describe '#days_remaining' do
    let(:user) { create(:user) }

    it 'returns nil when achieved' do
      entry = build(:post_entry, :achieved, user: user)
      expect(entry.days_remaining).to be_nil
    end

    it 'returns nil when deadline is blank' do
      entry = build(:post_entry, :without_deadline, user: user)
      expect(entry.days_remaining).to be_nil
    end

    it 'returns positive days when deadline is in the future' do
      entry = build(:post_entry, deadline: Date.current + 5.days, user: user)
      expect(entry.days_remaining).to eq(5)
    end

    it 'returns 0 when deadline is today' do
      entry = build(:post_entry, deadline: Date.current, user: user)
      expect(entry.days_remaining).to eq(0)
    end

    it 'returns negative days when deadline is past' do
      entry = build(:post_entry, deadline: Date.current - 3.days, user: user)
      expect(entry.days_remaining).to eq(-3)
    end
  end

  describe '#deadline_status' do
    let(:user) { create(:user) }

    it 'returns :achieved when achieved' do
      entry = build(:post_entry, :achieved, user: user)
      expect(entry.deadline_status).to eq(:achieved)
    end

    it 'returns :expired when past deadline' do
      entry = build(:post_entry, :overdue, user: user)
      expect(entry.deadline_status).to eq(:expired)
    end

    it 'returns :today when deadline is today' do
      entry = build(:post_entry, deadline: Date.current, user: user)
      expect(entry.deadline_status).to eq(:today)
    end

    it 'returns :urgent when deadline is tomorrow' do
      entry = build(:post_entry, deadline: Date.current + 1.day, user: user)
      expect(entry.deadline_status).to eq(:urgent)
    end

    it 'returns :warning when deadline is 2-3 days away' do
      entry = build(:post_entry, deadline: Date.current + 2.days, user: user)
      expect(entry.deadline_status).to eq(:warning)
    end

    it 'returns :normal when deadline is more than 3 days away' do
      entry = build(:post_entry, deadline: Date.current + 5.days, user: user)
      expect(entry.deadline_status).to eq(:normal)
    end
  end

  describe '#liked_by?' do
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }
    let(:entry) { create(:post_entry, user: user) }

    it 'returns false when user is nil' do
      expect(entry.liked_by?(nil)).to be false
    end

    it 'returns false when user has not liked' do
      expect(entry.liked_by?(other_user)).to be false
    end

    it 'returns true when user has liked' do
      EntryLike.create!(user: other_user, post_entry: entry)
      expect(entry.liked_by?(other_user)).to be true
    end
  end
end
