# spec/models/post_entry_spec.rb
# ==========================================
# PostEntry モデルのテスト
# ==========================================
#
# 【このファイルの役割】
# PostEntry（アクションプラン）モデルのバリデーション、
# アソシエーション、メソッドが正しく動作することを検証する。
#
# 【テストの実行方法】
#   docker compose exec web rspec spec/models/post_entry_spec.rb
#
# 【テスト対象】
# - バリデーション（content必須）
# - アソシエーション（post, user, entry_likes）
# - スコープ（recent, achieved, not_achieved, expired）
# - 達成機能（achieve!, achieved?）
# - 期限管理（days_remaining, deadline_status）
# - いいね機能（liked_by?）
# - サムネイル・画像のS3署名URL生成
# - 振り返り機能（achieve_with_reflection!, update_reflection!）
#
# 【ビジネスルール】
# ユーザーは複数の未達成アクションプランを持つことができる。
#
require 'rails_helper'

RSpec.describe PostEntry, type: :model do
  describe 'associations' do
    it { should belong_to(:post) }
    it { should belong_to(:user) }
    it { should have_many(:entry_likes).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:content) }

    describe 'multiple_action_plans' do
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

        it 'allows creating another entry on a different post' do
          entry = build(:post_entry, post: post2, user: user)
          expect(entry).to be_valid
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

  describe '#extract_s3_key (private)' do
    let(:user) { create(:user) }
    let(:entry) { create(:post_entry, user: user) }

    it 'returns the same string for non-URL' do
      expect(entry.send(:extract_s3_key, 'user_thumbnails/123/image.jpg')).to eq('user_thumbnails/123/image.jpg')
    end

    it 'extracts key from S3 URL' do
      url = 'https://bucket.s3.ap-northeast-1.amazonaws.com/user_thumbnails/123/image.jpg'
      expect(entry.send(:extract_s3_key, url)).to eq('user_thumbnails/123/image.jpg')
    end

    it 'returns nil for invalid URI' do
      expect(entry.send(:extract_s3_key, 'http://invalid[url')).to be_nil
    end
  end

  describe '#signed_thumbnail_url' do
    let(:user) { create(:user) }
    let(:entry) { create(:post_entry, user: user, thumbnail_url: 'user_thumbnails/123/image.jpg') }

    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('AWS_REGION').and_return('ap-northeast-1')
      allow(ENV).to receive(:[]).with('AWS_ACCESS_KEY_ID').and_return('test_key')
      allow(ENV).to receive(:[]).with('AWS_SECRET_ACCESS_KEY').and_return('test_secret')
      allow(ENV).to receive(:[]).with('AWS_BUCKET').and_return('test-bucket')
    end

    it 'returns nil when thumbnail_url is blank' do
      entry.thumbnail_url = nil
      expect(entry.signed_thumbnail_url).to be_nil
    end

    it 'generates presigned URL for S3 key' do
      s3_obj = instance_double(Aws::S3::Object)
      s3_bucket = instance_double(Aws::S3::Bucket)
      s3_resource = instance_double(Aws::S3::Resource)

      allow(Aws::S3::Resource).to receive(:new).and_return(s3_resource)
      allow(s3_resource).to receive(:bucket).and_return(s3_bucket)
      allow(s3_bucket).to receive(:object).and_return(s3_obj)
      allow(s3_obj).to receive(:presigned_url).and_return('https://signed-url.example.com')

      expect(entry.signed_thumbnail_url).to eq('https://signed-url.example.com')
    end

    it 'returns nil on S3 error' do
      allow(Aws::S3::Resource).to receive(:new).and_raise(Aws::S3::Errors::ServiceError.new(nil, 'Error'))

      expect(entry.signed_thumbnail_url).to be_nil
    end
  end

  describe '#signed_result_image_url' do
    let(:user) { create(:user) }
    let(:entry) { create(:post_entry, :achieved, user: user, result_image: 'results/123/image.jpg') }

    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('AWS_REGION').and_return('ap-northeast-1')
      allow(ENV).to receive(:[]).with('AWS_ACCESS_KEY_ID').and_return('test_key')
      allow(ENV).to receive(:[]).with('AWS_SECRET_ACCESS_KEY').and_return('test_secret')
      allow(ENV).to receive(:[]).with('AWS_BUCKET').and_return('test-bucket')
    end

    it 'returns nil when result_image is blank' do
      entry.result_image = nil
      expect(entry.signed_result_image_url).to be_nil
    end

    it 'generates presigned URL for S3 key' do
      s3_obj = instance_double(Aws::S3::Object)
      s3_bucket = instance_double(Aws::S3::Bucket)
      s3_resource = instance_double(Aws::S3::Resource)

      allow(Aws::S3::Resource).to receive(:new).and_return(s3_resource)
      allow(s3_resource).to receive(:bucket).and_return(s3_bucket)
      allow(s3_bucket).to receive(:object).and_return(s3_obj)
      allow(s3_obj).to receive(:presigned_url).and_return('https://signed-result-url.example.com')

      expect(entry.signed_result_image_url).to eq('https://signed-result-url.example.com')
    end
  end

  describe '#display_result_thumbnail_url' do
    let(:user) { create(:user) }
    let(:post_record) { create(:post) }
    let(:entry) { create(:post_entry, :achieved, user: user, post: post_record) }

    it 'returns YouTube thumbnail when no custom images' do
      expected_url = "https://i.ytimg.com/vi/#{post_record.youtube_video_id}/mqdefault.jpg"
      expect(entry.display_result_thumbnail_url).to eq(expected_url)
    end
  end

  describe '#achieve_with_reflection!' do
    let(:user) { create(:user) }
    let(:entry) { create(:post_entry, user: user) }

    it 'sets achieved_at' do
      entry.achieve_with_reflection!
      expect(entry.achieved_at).to be_present
    end

    it 'sets reflection when provided' do
      entry.achieve_with_reflection!(reflection_text: '達成できました！')
      expect(entry.reflection).to eq('達成できました！')
    end

    it 'sets result_image when S3 key provided' do
      entry.achieve_with_reflection!(result_image_s3_key: 'results/123/image.jpg')
      expect(entry.result_image).to eq('results/123/image.jpg')
    end

    it 'sets both reflection and result_image' do
      entry.achieve_with_reflection!(
        reflection_text: '頑張りました',
        result_image_s3_key: 'results/456/proof.jpg'
      )
      expect(entry.reflection).to eq('頑張りました')
      expect(entry.result_image).to eq('results/456/proof.jpg')
      expect(entry.achieved?).to be true
    end
  end

  describe '#update_reflection!' do
    let(:user) { create(:user) }
    let(:entry) { create(:post_entry, :achieved, user: user, reflection: 'Old') }

    it 'updates reflection' do
      entry.update_reflection!(reflection_text: 'New reflection')
      expect(entry.reload.reflection).to eq('New reflection')
    end
  end

  describe 'set_auto_deadline callback' do
    let(:user) { create(:user) }

    it 'sets deadline to 7 days from now when not provided' do
      entry = create(:post_entry, user: user, deadline: nil)
      expect(entry.deadline).to eq(Date.current + 7.days)
    end

    it 'does not override provided deadline' do
      custom_deadline = Date.current + 14.days
      entry = create(:post_entry, user: user, deadline: custom_deadline)
      expect(entry.deadline).to eq(custom_deadline)
    end
  end

  describe 'reflection validation' do
    let(:user) { create(:user) }

    it 'allows reflection up to 500 characters' do
      entry = build(:post_entry, user: user, reflection: 'a' * 500)
      expect(entry).to be_valid
    end

    it 'rejects reflection over 500 characters' do
      entry = build(:post_entry, user: user, reflection: 'a' * 501)
      expect(entry).not_to be_valid
    end

    it 'allows blank reflection' do
      entry = build(:post_entry, user: user, reflection: '')
      expect(entry).to be_valid
    end
  end

  describe 'deadline_status edge cases' do
    let(:user) { create(:user) }

    it 'returns :expired when deadline is nil' do
      entry = build(:post_entry, :without_deadline, user: user)
      expect(entry.deadline_status).to eq(:expired)
    end

    it 'returns :warning for 3 days away' do
      entry = build(:post_entry, deadline: Date.current + 3.days, user: user)
      expect(entry.deadline_status).to eq(:warning)
    end
  end
end
