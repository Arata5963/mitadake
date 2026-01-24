# spec/system/posts_spec.rb
# ==========================================
# 投稿関連のシステムテスト
# ==========================================
#
# 【このファイルの役割】
# 投稿（YouTube動画）の作成、一覧、詳細、編集、削除の
# エンドツーエンドテストを行う。
#
# 【テストの実行方法】
#   docker compose exec web rspec spec/system/posts_spec.rb
#
# 【テスト対象】
# - 投稿作成（JavaScript必須のためスキップ）
# - 投稿一覧表示
# - 投稿詳細表示
# - 投稿編集（権限チェック含む）
# - 投稿削除（エントリー削除）
#
# 【注意】
# 現在のUIはStimulusコントローラーを使用しているため、
# 投稿作成フローは rack_test ではテストできない。
# 代わりに request spec でAPIレベルのテストを行う。
#
# 【page.driver.submit】
# Capybara の rack_test ドライバーで
# DELETE リクエストを直接送信する方法。
#
#   page.driver.submit :delete, post_path(post), {}
#
require 'rails_helper'

RSpec.describe "Posts", type: :system do
  # JavaScript を使わないシンプルなテストの場合は rack_test を使用
  before do
    driven_by(:rack_test)
  end

  # ====================
  # 投稿作成フロー（JavaScript必須のためスキップ）
  # ====================
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

  # ====================
  # 投稿一覧表示
  # ====================
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

  # ====================
  # 投稿詳細表示
  # ====================
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

  # ====================
  # 投稿編集
  # ====================
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

  # ====================
  # 投稿削除（エントリー削除）
  # ====================
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
