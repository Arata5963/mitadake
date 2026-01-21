# spec/system/password_toggle_spec.rb
# ==========================================
# パスワード表示/非表示機能のシステムテスト
# ==========================================
#
# 【このファイルの役割】
# パスワード入力フィールドの表示/非表示トグル機能を
# テストする。Stimulusコントローラーで実装。
#
# 【テストの実行方法】
#   docker compose exec web rspec spec/system/password_toggle_spec.rb
#
# 【テスト対象】
# - 新規登録ページ（password + password_confirmation）
# - ログインページ（password）
# - パスワードリセットページ（password + confirmation）
# - プロフィール編集ページ（new password + confirmation + current）
# - アクセシビリティ（aria-label, キーボード操作）
#
# 【HTML構造の確認】
# rack_test ではJavaScriptが動作しないが、
# HTML要素の存在は確認できる。
#
#   expect(page).to have_css('input[type="password"]')
#   expect(page).to have_css('button[data-action*="password-toggle#toggle"]')
#   expect(page).to have_css('[data-controller="password-toggle"]')
#
require 'rails_helper'

RSpec.describe 'パスワード表示/非表示機能', type: :system do
  # rack_testを使用（JavaScriptは動作しないが、HTML構造はテスト可能）
  before do
    driven_by(:rack_test)
  end

  describe '新規登録ページ' do
    before do
      visit new_user_registration_path
    end

    it 'パスワードフィールドに表示/非表示ボタンが存在する' do
      # パスワードフィールド（2つ: password + password_confirmation）
      expect(page).to have_css('input[type="password"][data-password-toggle-target="input"]', count: 2)

      # 表示/非表示ボタン（2つ）
      expect(page).to have_css('button[data-action*="password-toggle#toggle"]', count: 2)

      # Eyeアイコン（2つ）
      expect(page).to have_css('svg[data-password-toggle-target="iconShow"]', count: 2)

      # Eye-Slashアイコン（2つ）
      expect(page).to have_css('svg[data-password-toggle-target="iconHide"]', count: 2)
    end

    it 'aria-labelが設定されている' do
      toggle_buttons = all('button[data-action*="password-toggle#toggle"]')
      toggle_buttons.each do |button|
        expect(button['aria-label']).to eq('パスワードを表示/非表示')
      end
    end

    it 'ボタンのtype属性が"button"である' do
      toggle_buttons = all('button[data-action*="password-toggle#toggle"]')
      toggle_buttons.each do |button|
        expect(button[:type]).to eq('button')
      end
    end

    it 'SVGアイコンにaria-hidden="true"が設定されている' do
      svg_icons = all('svg[data-password-toggle-target]')
      svg_icons.each do |svg|
        expect(svg['aria-hidden']).to eq('true')
      end
    end
  end

  describe 'ログインページ' do
    before do
      visit new_user_session_path
    end

    it 'パスワードフィールドに表示/非表示ボタンが存在する' do
      # パスワードフィールド（1つ）
      expect(page).to have_css('input[type="password"][data-password-toggle-target="input"]', count: 1)

      # 表示/非表示ボタン（1つ）
      expect(page).to have_css('button[data-action*="password-toggle#toggle"]', count: 1)
    end

    it 'Stimulus Controllerが接続されている' do
      expect(page).to have_css('[data-controller="password-toggle"]', count: 1)
    end
  end

  describe 'パスワードリセットページ' do
    let(:user) { create(:user) }

    before do
      # パスワードリセットトークンを生成してページにアクセス
      token = user.send(:set_reset_password_token)
      visit edit_user_password_path(reset_password_token: token)
    end

    it 'パスワードフィールドに表示/非表示ボタンが存在する（新しいパスワード×2）' do
      # パスワードフィールド（2つ: password + password_confirmation）
      expect(page).to have_css('input[type="password"][data-password-toggle-target="input"]', count: 2)

      # 表示/非表示ボタン（2つ）
      expect(page).to have_css('button[data-action*="password-toggle#toggle"]', count: 2)
    end

    it 'Stimulus Controllerが接続されている' do
      expect(page).to have_css('[data-controller="password-toggle"]', count: 2)
    end
  end

  describe 'プロフィール編集ページ（アカウント設定）' do
    let(:user) { create(:user) }

    before do
      sign_in user
      visit edit_user_registration_path
    end

    it 'パスワードフィールドに表示/非表示ボタンが存在する（新×2 + 現在×1）' do
      # 新しいパスワード、新しいパスワード確認、現在のパスワード（3つ）
      expect(page).to have_css('input[type="password"][data-password-toggle-target="input"]', count: 3)

      # 表示/非表示ボタン（3つ）
      expect(page).to have_css('button[data-action*="password-toggle#toggle"]', count: 3)
    end

    it 'Stimulus Controllerが接続されている' do
      expect(page).to have_css('[data-controller="password-toggle"]', count: 3)
    end
  end

  describe 'アクセシビリティ（全ページ共通）' do
    it '新規登録ページのボタンがキーボードアクセス可能' do
      visit new_user_registration_path

      # ボタン要素なのでデフォルトでキーボードアクセス可能
      toggle_buttons = all('button[data-action*="password-toggle#toggle"]')
      expect(toggle_buttons.count).to eq(2)
    end

    it 'ログインページのボタンがキーボードアクセス可能' do
      visit new_user_session_path

      toggle_buttons = all('button[data-action*="password-toggle#toggle"]')
      expect(toggle_buttons.count).to eq(1)
    end
  end
end
