# spec/requests/pages_spec.rb
# ==========================================
# Pages コントローラーのリクエストテスト
# ==========================================
#
# 【このファイルの役割】
# 静的ページ（利用規約・プライバシーポリシー）が
# 正常に表示されることを検証する。
#
# 【テストの実行方法】
#   docker compose exec web rspec spec/requests/pages_spec.rb
#
# 【テスト対象】
# - GET /terms（利用規約）
# - GET /privacy（プライバシーポリシー）
#
# 【リクエストテストとは？】
# HTTP リクエストを実際に送信して、レスポンスを検証するテスト。
# コントローラーのアクション全体（ルーティング含む）をテストできる。
#
#   get terms_path
#   expect(response).to have_http_status(:success)
#
require 'rails_helper'

RSpec.describe 'Pages', type: :request do
  describe 'GET /terms' do
    it '利用規約ページが表示される' do
      get terms_path
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET /privacy' do
    it 'プライバシーポリシーページが表示される' do
      get privacy_path
      expect(response).to have_http_status(:success)
    end
  end
end
