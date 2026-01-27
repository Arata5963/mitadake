# 投稿関連のシステムテスト
# 投稿のCRUD操作をE2Eで検証

require 'rails_helper'

RSpec.describe "Posts", type: :system do
  before do
    driven_by(:rack_test)
  end

  describe "投稿作成" do
    let(:user) { create(:user) }

    context "ログイン済みの場合", :skip do
      # 現在のUIはStimulusコントローラを使用しているため、
      # rack_testでは投稿作成をテストできない
      # request specでAPIレベルのテストを行う
    end

    context "未ログインの場合" do
      it "ログインページにリダイレクトされる" do
        visit new_post_path
        expect(page).to have_current_path(new_user_session_path)
      end
    end
  end

  describe "投稿一覧" do
    let(:user) { create(:user) }

    context "ログイン済みユーザー" do
      before { sign_in user }

      context "エントリーがある投稿が存在する場合" do
        let!(:post1) { create(:post, youtube_title: "投稿1のタイトル") }
        let!(:post2) { create(:post, youtube_title: "投稿2のタイトル") }

        before do
          # 異なるユーザーでエントリーを作成
          create(:post_entry, :achieved, post: post1, user: create(:user), content: "投稿1のアクション")
          create(:post_entry, :achieved, post: post2, user: create(:user), content: "投稿2のアクション")
        end

        it "投稿一覧が表示される" do
          visit posts_path
          expect(page).to have_http_status(:success)
        end
      end
    end

    context "未ログインユーザー" do
      it "ランディングページが表示される" do
        visit root_path
        expect(page).to have_http_status(:success)
      end
    end
  end

  describe "投稿詳細" do
    let(:user) { create(:user) }
    let!(:post_record) { create(:post, youtube_title: "詳細テスト動画") }
    let!(:entry) { create(:post_entry, post: post_record, user: user, content: "詳細テストアクション") }

    it "投稿の詳細が表示される" do
      visit post_path(post_record)
      # 動画タイトルが表示される
      expect(page).to have_content("詳細テスト動画")
      # 達成したアクションセクションが表示される
      expect(page).to have_content("達成したアクション")
    end
  end

  describe "投稿編集" do
    let(:user) { create(:user) }
    let!(:post_record) { create(:post, youtube_title: "編集テスト動画") }

    context "エントリー所有者の場合" do
      before do
        create(:post_entry, post: post_record, user: user, content: "編集前のアクション")
        sign_in user
      end

      it "編集ページにアクセスできる" do
        visit edit_post_path(post_record)
        expect(page).to have_http_status(:success)
      end
    end

    context "エントリー所有者でない場合" do
      let(:other_user) { create(:user) }

      before do
        create(:post_entry, post: post_record, user: other_user, content: "他人のアクション")
        sign_in user
      end

      it "詳細ページにリダイレクトされる" do
        visit edit_post_path(post_record)
        expect(page).to have_current_path(post_path(post_record))
      end
    end
  end

  describe "投稿削除" do
    let(:user) { create(:user) }
    let!(:post_record) { create(:post, youtube_title: "削除テスト動画") }
    let!(:entry) { create(:post_entry, post: post_record, user: user, content: "削除するアクション") }

    context "エントリー所有者の場合" do
      before { sign_in user }

      it "削除リクエストでエントリーが削除される" do
        expect {
          page.driver.submit :delete, post_path(post_record), {}
        }.to change(PostEntry, :count).by(-1)
      end
    end
  end
end
