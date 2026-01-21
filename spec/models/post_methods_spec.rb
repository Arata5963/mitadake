# spec/models/post_methods_spec.rb
# ==========================================
# Post モデルのメソッドテスト（追加機能）
# ==========================================
#
# 【このファイルの役割】
# Post モデルのRansack検索機能と依存削除をテストする。
# post_spec.rb を補完するテスト。
#
# 【テストの実行方法】
#   docker compose exec web rspec spec/models/post_methods_spec.rb
#
# 【テスト対象】
# - ransackable_attributes（検索可能な属性）
# - ransackable_associations（検索可能なアソシエーション）
# - dependent destroy（投稿削除時のエントリー削除）
#
# 【Ransackとは？】
# 検索機能を簡単に実装できるgem。
# ransackable_attributes で検索可能な属性を制限できる。
#
#   Post.ransack(youtube_title_cont: "Ruby")
#     → youtube_title に "Ruby" を含む投稿を検索
#
require 'rails_helper'

RSpec.describe Post, type: :model do
  describe '.ransackable_attributes' do
    it '検索可能な属性のリストを返す' do
      attributes = Post.ransackable_attributes
      expect(attributes).to include('action_plan')
      expect(attributes).to include('youtube_title')
      expect(attributes).to include('youtube_channel_name')
      expect(attributes).to include('created_at')
    end

    it '検索可能な属性は配列である' do
      attributes = Post.ransackable_attributes
      expect(attributes).to be_an(Array)
    end

    it 'すべての検索可能属性が文字列である' do
      attributes = Post.ransackable_attributes
      expect(attributes).to all(be_a(String))
    end
  end

  describe '.ransackable_associations' do
    it '検索可能なアソシエーションのリストを返す' do
      associations = Post.ransackable_associations
      expect(associations).to include('user')
    end

    it '検索可能なアソシエーションは配列である' do
      associations = Post.ransackable_associations
      expect(associations).to be_an(Array)
    end

    it 'すべての検索可能アソシエーションが文字列である' do
      associations = Post.ransackable_associations
      expect(associations).to all(be_a(String))
    end
  end

  describe 'dependent destroy' do
    let(:user) { create(:user) }
    let(:post) { create(:post, user: user) }

    it '投稿を削除するとアクションプランも削除される' do
      create(:post_entry, user: user, post: post, deadline: 1.week.from_now)

      expect {
        post.destroy
      }.to change(PostEntry, :count).by(-1)
    end
  end
end
