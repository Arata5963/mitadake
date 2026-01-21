# spec/requests/api/presigned_urls_spec.rb
# ==========================================
# Presigned URLs API のリクエストテスト
# ==========================================
#
# 【このファイルの役割】
# S3 署名付きURLを生成するAPIエンドポイントをテストする。
# フロントエンドから直接S3にアップロードするための事前署名URL。
#
# 【テストの実行方法】
#   docker compose exec web rspec spec/requests/api/presigned_urls_spec.rb
#
# 【テスト対象】
# - POST /api/presigned_urls
#   - 認証チェック（ログイン必須）
#   - 許可されたファイル形式（jpeg, png, webp）
#   - 不許可のファイル形式（gif, html等）
#   - 生成されるS3キーにユーザーIDが含まれる
#
# 【Presigned URL とは？】
# S3バケットへの一時的なアクセス権を付与するURL。
# サーバー経由せずクライアントから直接S3にアップロードできる。
#
#   POST /api/presigned_urls
#   { filename: 'image.jpg', content_type: 'image/jpeg' }
#   → { upload_url: 'https://s3.../...?signature=...', s3_key: 'user_thumbnails/123/...' }
#
# 【AWS SDK モック】
# Aws::S3::Presigner をモック化してテスト。
#
require 'rails_helper'

RSpec.describe 'Api::PresignedUrls', type: :request do
  let(:user) { create(:user) }
  let(:valid_params) { { filename: 'test.jpg', content_type: 'image/jpeg' } }

  before do
    # AWS環境変数をモック
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('AWS_REGION').and_return('ap-northeast-1')
    allow(ENV).to receive(:[]).with('AWS_ACCESS_KEY_ID').and_return('test_key')
    allow(ENV).to receive(:[]).with('AWS_SECRET_ACCESS_KEY').and_return('test_secret')
    allow(ENV).to receive(:[]).with('AWS_BUCKET').and_return('test-bucket')

    # S3 Presignerをモック
    presigner = instance_double(Aws::S3::Presigner)
    allow(Aws::S3::Presigner).to receive(:new).and_return(presigner)
    allow(presigner).to receive(:presigned_url).and_return('https://s3.example.com/presigned-url')
  end

  describe 'POST /api/presigned_urls' do
    context '未ログインの場合' do
      it 'ログインページにリダイレクトされる' do
        post api_presigned_urls_path, params: valid_params
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'ログイン済みの場合' do
      before { sign_in user }

      context '有効なcontent_type (image/jpeg)' do
        it '署名付きURLを返す' do
          post api_presigned_urls_path, params: { filename: 'test.jpg', content_type: 'image/jpeg' }
          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json['upload_url']).to be_present
          expect(json['s3_key']).to include('.jpg')
        end
      end

      context '有効なcontent_type (image/png)' do
        it '署名付きURLを返す' do
          post api_presigned_urls_path, params: { filename: 'test.png', content_type: 'image/png' }
          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json['s3_key']).to include('.png')
        end
      end

      context '有効なcontent_type (image/webp)' do
        it '署名付きURLを返す' do
          post api_presigned_urls_path, params: { filename: 'test.webp', content_type: 'image/webp' }
          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json['s3_key']).to include('.webp')
        end
      end

      context '無効なcontent_type' do
        it 'エラーを返す' do
          post api_presigned_urls_path, params: { filename: 'test.gif', content_type: 'image/gif' }
          expect(response).to have_http_status(:unprocessable_entity)
          json = JSON.parse(response.body)
          expect(json['error']).to eq('許可されていないファイル形式です')
        end
      end

      context '不正なcontent_type (text/html)' do
        it 'エラーを返す' do
          post api_presigned_urls_path, params: { filename: 'test.html', content_type: 'text/html' }
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      it 's3_keyにユーザーIDが含まれる' do
        post api_presigned_urls_path, params: valid_params
        json = JSON.parse(response.body)
        expect(json['s3_key']).to include("user_thumbnails/#{user.id}/")
      end
    end
  end
end
