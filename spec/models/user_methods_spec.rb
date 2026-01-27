# User モデルのメソッドテスト（追加機能）
# CarrierWaveアバターとDeviseパスワードバリデーションを検証

require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'avatar (CarrierWave)' do
    let(:user) { create(:user) }

    context 'アバター画像がアップロードされていない場合' do
      it 'avatarはnilまたは空である' do
        expect(user.avatar.present?).to be_falsy
      end
    end

    context 'アバター画像がアップロードされている場合', skip: 'ImageMagickが必要なためCI環境ではスキップ' do
      let(:user_with_avatar) { create(:user, :with_avatar) }

      it 'avatarが存在する' do
        expect(user_with_avatar.avatar.present?).to be true
      end

      it 'avatarのURLが生成される' do
        expect(user_with_avatar.avatar.url).to be_present
      end

      it 'サムネイルURLが生成される' do
        expect(user_with_avatar.avatar.thumb.url).to be_present
      end
    end
  end

  describe 'password validation (Devise)' do
    context '新規ユーザー作成時' do
      it 'パスワードが短すぎる場合はエラー' do
        user = build(:user, password: '12345', password_confirmation: '12345')
        expect(user).not_to be_valid
        expect(user.errors[:password]).to be_present
      end

      it 'パスワードが十分な長さの場合は有効' do
        user = build(:user, password: '123456', password_confirmation: '123456')
        expect(user).to be_valid
      end

      it 'パスワード確認が一致しない場合はエラー' do
        user = build(:user, password: '123456', password_confirmation: 'different')
        expect(user).not_to be_valid
        expect(user.errors[:password_confirmation]).to be_present
      end
    end
  end
end
