# spec/system/authentication_spec.rb
# ==========================================
# 認証機能のシステムテスト
# ==========================================
#
# 【このファイルの役割】
# ユーザー登録、ログイン、ログアウトの
# エンドツーエンド（E2E）テストを行う。
#
# 【テストの実行方法】
#   docker compose exec web rspec spec/system/authentication_spec.rb
#
# 【テスト対象】
# - ユーザー登録（新規登録、バリデーションエラー）
# - ログイン（成功、失敗）
# - ログアウト
#
# 【システムテストとは？】
# ブラウザを使って実際のユーザー操作をシミュレートするテスト。
# Capybara を使用してページ遷移やフォーム入力をテストできる。
#
#   visit new_user_registration_path   # ページにアクセス
#   fill_in 'user_email', with: 'test@example.com'  # フォーム入力
#   click_button '登録する'            # ボタンクリック
#   expect(page).to have_content('成功')  # 画面確認
#
# 【driven_by(:rack_test)】
# JavaScriptを使わないシンプルなテストドライバー。
# 高速だがJavaScriptの動作はテストできない。
#
require 'rails_helper'

RSpec.describe "Authentication", type: :system do
  before do
    driven_by(:rack_test)
  end

  # ====================
  # ユーザー登録
  # ====================
  describe "ユーザー登録" do
    it "新規ユーザーが登録できる" do
      # 1. 新規登録ページに直接アクセス
      visit new_user_registration_path

      # 2. 新規登録フォームが表示される
      expect(page).to have_content("新規登録")

      # 3. フォームに入力（実際のフィールドIDを使用）
      fill_in "user_name", with: "テストユーザー"
      fill_in "user_email", with: "test@example.com"
      fill_in "user_password", with: "password123"
      fill_in "user_password_confirmation", with: "password123"

      # 4. 登録ボタンをクリック（実際のボタンテキスト: "登録する"）
      click_button "登録する"

      # 5. トップページにリダイレクトされる
      expect(page).to have_current_path(root_path)

      # 6. ログイン状態になる（ログアウトのテキストが表示される）
      expect(page).to have_content("ログアウト")
    end

    it "バリデーションエラーが表示される" do
      # 1. 新規登録ページにアクセス
      visit new_user_registration_path

      # 2. パスワードを短くして登録を試みる
      fill_in "user_name", with: "テストユーザー"
      fill_in "user_email", with: "test@example.com"
      fill_in "user_password", with: "short"
      fill_in "user_password_confirmation", with: "short"

      # 3. 登録ボタンをクリック
      click_button "登録する"

      # 4. エラーメッセージが表示される
      expect(page).to have_content("件のエラーがあります")
    end
  end

  # ====================
  # ログイン・ログアウト
  # ====================
  describe "ログイン・ログアウト" do
    let!(:user) { create(:user, email: "login@example.com", password: "password123") }

    it "ユーザーがログインできる" do
      # 1. ログインページにアクセス
      visit new_user_session_path

      # 2. フォームに入力
      fill_in "user_email", with: "login@example.com"
      fill_in "user_password", with: "password123"

      # 3. ログインボタンをクリック
      click_button "ログイン"

      # 4. トップページにリダイレクトされる
      expect(page).to have_current_path(root_path)

      # 5. ログアウトのテキストが表示される
      expect(page).to have_content("ログアウト")
    end

    it "間違ったパスワードでログインできない" do
      # 1. ログインページにアクセス
      visit new_user_session_path

      # 2. 間違ったパスワードを入力
      fill_in "user_email", with: "login@example.com"
      fill_in "user_password", with: "wrongpassword"

      # 3. ログインボタンをクリック
      click_button "ログイン"

      # 4. エラーメッセージが表示される
      expect(page).to have_content("メールアドレスまたはパスワードが違います")
    end

    it "ユーザーがログアウトできる" do
      # 事前にログイン
      sign_in user

      # 1. トップページにアクセス
      visit root_path

      # 2. ログアウトリンクをクリック（visible: false で非表示要素も検索）
      # rack_test では <details> が閉じた状態でも要素は存在するが visible: false
      click_link "ログアウト", visible: false

      # 3. ログインページにリダイレクトされる
      expect(page).to have_current_path(new_user_session_path)

      # 4. ログインのテキストが表示される
      expect(page).to have_content("ログイン")
    end
  end
end
