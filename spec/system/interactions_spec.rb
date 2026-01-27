# インタラクションのシステムテスト
# 達成記録の画面表示と閲覧制御を検証

require 'rails_helper'

RSpec.describe "Interactions", type: :system do
  before do
    driven_by(:rack_test)
  end

  describe "達成記録" do
    let(:user) { create(:user) }
    let!(:post_record) { create(:post, youtube_title: "テスト動画") }

    context "自分のエントリーがある場合" do
      let!(:entry) { create(:post_entry, post: post_record, user: user, content: "テストアクション", achieved_at: nil) }

      before do
        sign_in user
      end

      it "詳細ページで動画情報が表示される" do
        visit post_path(post_record)

        # 動画タイトルが表示される
        expect(page).to have_content "テスト動画"
        # 達成したアクションセクションが表示される
        expect(page).to have_content "達成したアクション"
      end

      # Note: 達成ボタンはJavaScriptで動作するため、request specでテスト
    end

    context "達成済みエントリーの場合" do
      let!(:entry) { create(:post_entry, :achieved, post: post_record, user: user, content: "達成済みアクション") }

      before do
        sign_in user
      end

      it "達成済みの状態が表示される" do
        visit post_path(post_record)

        # エントリー内容が表示される
        expect(page).to have_content "達成済みアクション"
      end
    end
  end

  describe "未ログイン時の制御" do
    let!(:post_record) { create(:post, youtube_title: "公開動画") }
    let!(:entry) { create(:post_entry, :achieved, post: post_record, user: create(:user), content: "公開アクション") }

    it "投稿詳細は閲覧できる" do
      visit post_path(post_record)

      # 投稿タイトルとエントリー内容が表示される
      expect(page).to have_content "公開動画"
      expect(page).to have_content "公開アクション"
    end
  end
end
