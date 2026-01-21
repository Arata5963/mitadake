# spec/models/factory_test_spec.rb
# ==========================================
# Factory（テストデータ生成）の動作確認テスト
# ==========================================
#
# 【このファイルの役割】
# FactoryBotで定義したファクトリが正しく動作することを確認する。
# ファクトリに問題があると、他のテストが全て失敗するため重要。
#
# 【テストの実行方法】
#   docker compose exec web rspec spec/models/factory_test_spec.rb
#
# 【テスト対象】
# - User Factory（基本作成、メール重複なし）
# - Post Factory（基本作成、ユーザー付き作成）
# - PostEntry Factory（基本作成、関連付け確認）
#
# 【FactoryBotとは？】
# テストデータを簡単に作成できるgem。
# spec/factories/ にファクトリ定義ファイルがある。
#
#   create(:user)              # DBに保存
#   build(:user)               # DBに保存しない
#   create(:post, :with_user)  # trait（オプション）付き
#
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
