# EntryLike モデルのテスト
# いいね機能のバリデーション、ユニーク制約、依存削除を検証

require 'rails_helper'

RSpec.describe EntryLike, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:post_entry) }
  end

  describe 'validations' do
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }
    let(:entry) { create(:post_entry, user: user) }

    context 'uniqueness of user_id scoped to post_entry_id' do
      it 'allows same user to like different entries' do
        entry2 = create(:post_entry, user: user, achieved_at: Time.current)
        user.post_entries.first.update!(achieved_at: Time.current)
        entry3 = create(:post_entry, user: other_user)

        like1 = EntryLike.create!(user: other_user, post_entry: entry)
        like2 = EntryLike.build(user: other_user, post_entry: entry3)
        expect(like2).to be_valid
      end

      it 'allows different users to like same entry' do
        user3 = create(:user)
        EntryLike.create!(user: other_user, post_entry: entry)
        like = EntryLike.build(user: user3, post_entry: entry)
        expect(like).to be_valid
      end

      it 'rejects duplicate like from same user on same entry' do
        EntryLike.create!(user: other_user, post_entry: entry)
        duplicate = EntryLike.build(user: other_user, post_entry: entry)
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:user_id]).to be_present
      end
    end
  end

  describe 'dependent destroy' do
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }
    let(:entry) { create(:post_entry, user: user) }

    it 'is destroyed when post_entry is destroyed' do
      EntryLike.create!(user: other_user, post_entry: entry)
      expect { entry.destroy }.to change(EntryLike, :count).by(-1)
    end

    it 'is destroyed when user is destroyed' do
      EntryLike.create!(user: other_user, post_entry: entry)
      expect { other_user.destroy }.to change(EntryLike, :count).by(-1)
    end
  end

  describe 'counting likes' do
    let(:user) { create(:user) }
    let(:entry) { create(:post_entry, user: user) }

    it 'counts likes correctly' do
      3.times { EntryLike.create!(user: create(:user), post_entry: entry) }
      expect(entry.entry_likes.count).to eq(3)
    end
  end
end
