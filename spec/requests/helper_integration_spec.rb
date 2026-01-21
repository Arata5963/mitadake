# spec/requests/helper_integration_spec.rb
# ==========================================
# ヘルパー統合テスト（カバレッジ向上用）
# ==========================================
#
# 【このファイルの役割】
# ApplicationHelperが実際のページで正しく動作することを検証する。
# ヘルパー単体テストを補完する統合テスト。
#
# 【テストの実行方法】
#   docker compose exec web rspec spec/requests/helper_integration_spec.rb
#
# 【テスト対象】
# - default_meta_tags が実際のHTMLに反映されるか
# - OGPタグ（og:title, og:description, og:image）の存在確認
#
# 【なぜ統合テストが必要？】
# ヘルパー単体テストでは、実際のビューでヘルパーが
# 呼び出されることを確認できない。
# 統合テストで実際のページを表示して検証する。
#
require 'rails_helper'

RSpec.describe "Helper Integration (カバレッジ向上)", type: :request do
  let(:user) { create(:user) }
  let(:post_record) { create(:post, user: user) }

  describe "ApplicationHelper統合テスト" do
    context "OGPメタタグが設定される（default_meta_tagsメソッドが実行される）" do
      it "トップページにOGPタグが含まれる" do
        get root_path
        expect(response).to have_http_status(:success)

        # OGPメタタグの存在確認（default_meta_tagsが実行された証拠）
        expect(response.body).to include('og:title')
        expect(response.body).to include('og:description')
        expect(response.body).to include('og:image')
        expect(response.body).to include('mitadake?')
      end

      it "投稿一覧ページにもOGPタグが含まれる" do
        sign_in user
        get posts_path
        expect(response).to have_http_status(:success)

        expect(response.body).to include('og:title')
        expect(response.body).to include('mitadake?')
      end
    end
  end
end
