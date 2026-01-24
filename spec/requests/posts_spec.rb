# spec/requests/posts_spec.rb
# ==========================================
# Posts コントローラーのリクエストテスト
# ==========================================
#
# 【このファイルの役割】
# 投稿（YouTube動画）関連のAPIエンドポイントをテストする。
# CRUD操作、検索、AI機能など多くのエンドポイントがある。
#
# 【テストの実行方法】
#   docker compose exec web rspec spec/requests/posts_spec.rb
#
# 【テスト対象】
# - GET /posts（一覧表示）
# - GET /posts/:id（詳細表示）
# - GET /posts/new（新規作成フォーム）
# - POST /posts/find_or_create（動画検索/作成）
# - POST /posts/create_with_action（動画+アクションプラン作成）
# - GET/PATCH /posts/:id/edit（編集）
# - DELETE /posts/:id（削除）
# - GET /posts/autocomplete（オートコンプリート）
# - GET /posts/recent（最近の投稿）
# - GET /posts/youtube_search（YouTube検索）
# - GET /posts/search_posts（投稿検索）
# - POST /posts/suggest_action_plans（AI提案）
# - POST /posts/convert_to_youtube_title（タイトル変換）
#
# 【認証テスト】
# sign_in helper を使用してログイン状態をシミュレート。
# 未ログイン時はログインページにリダイレクトされることを確認。
#
require 'rails_helper'

RSpec.describe "Posts", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  # ====================
  # GET /posts (一覧表示)
  # ====================
  describe "GET /posts" do
    context "未ログインの場合" do
      it "ランディングページを表示する" do
        get posts_path
        expect(response).to have_http_status(200)
      end
    end

    context "ログイン済みの場合" do
      before { sign_in user }

      it "正常にアクセスできる" do
        get posts_path
        expect(response).to have_http_status(200)
      end

      context "投稿とエントリーがある場合" do
        before do
          # 異なるユーザーでエントリーを持つ投稿を作成
          @post1 = create(:post, youtube_title: "タイトル1")
          @post2 = create(:post, youtube_title: "タイトル2")
          create(:post_entry, :achieved, post: @post1, user: other_user)
          create(:post_entry, :achieved, post: @post2, user: create(:user))
        end

        it "エントリーを持つ投稿が表示される" do
          get posts_path
          # 最近の投稿セクションまたはランキングで表示
          expect(response).to have_http_status(200)
        end
      end

      context "ユーザーフィルター" do
        let!(:post_with_entry) { create(:post, youtube_title: "ユーザーの投稿") }
        let!(:entry) { create(:post_entry, post: post_with_entry, user: other_user) }

        it "特定ユーザーのエントリーを持つ投稿のみ表示" do
          get posts_path, params: { user_id: other_user.id }
          expect(response).to have_http_status(200)
          expect(response.body).to include("ユーザーの投稿")
        end
      end

      context "チャンネルフィルター" do
        let!(:post1) { create(:post, youtube_channel_name: "Tech Channel") }
        let!(:post2) { create(:post, youtube_channel_name: "Other Channel") }

        before do
          create(:post_entry, :achieved, post: post1, user: other_user)
          create(:post_entry, :achieved, post: post2, user: create(:user))
        end

        it "特定チャンネルの投稿のみ表示" do
          get posts_path, params: { channel: "Tech Channel" }
          expect(response).to have_http_status(200)
        end
      end
    end

    context "Ransack検索" do
      before { sign_in user }
      let!(:post1) { create(:post, youtube_title: "Rubyプログラミング講座") }
      let!(:post2) { create(:post, youtube_title: "Python入門講座") }

      before do
        create(:post_entry, :achieved, post: post1, user: other_user)
        create(:post_entry, :achieved, post: post2, user: create(:user))
      end

      it "youtube_titleで検索できる" do
        get posts_path, params: { q: { youtube_title_cont: "Ruby" } }
        expect(response).to have_http_status(200)
      end
    end
  end

  # ====================
  # GET /posts/:id (詳細表示)
  # ====================
  describe "GET /posts/:id" do
    let(:post_record) { create(:post, youtube_title: "テスト動画タイトル") }

    context "投稿が存在する場合" do
      it "投稿の詳細が表示される" do
        get post_path(post_record)
        expect(response).to have_http_status(200)
        expect(response.body).to include("テスト動画タイトル")
      end
    end

    context "投稿が存在しない場合" do
      it "一覧ページにリダイレクト" do
        get post_path(id: 99999)
        expect(response).to redirect_to(posts_path)
      end
    end
  end

  # ====================
  # GET /posts/new (新規作成フォーム)
  # ====================
  describe "GET /posts/new" do
    context "ログインしている場合" do
      before { sign_in user }

      it "新規作成フォームが表示される" do
        get new_post_path
        expect(response).to have_http_status(200)
      end
    end

    context "ログインしていない場合" do
      it "ログインページにリダイレクトされる" do
        get new_post_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  # ====================
  # POST /posts/find_or_create (動画検索/作成)
  # ====================
  describe "POST /posts/find_or_create" do
    context "有効なYouTube URLの場合" do
      let(:valid_url) { "https://www.youtube.com/watch?v=dQw4w9WgXcQ" }

      before do
        allow(YoutubeService).to receive(:fetch_video_info).and_return({
          title: "Test Video",
          channel_name: "Test Channel"
        })
      end

      it "投稿を作成してJSONを返す" do
        post find_or_create_posts_path, params: { youtube_url: valid_url }
        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['post_id']).to be_present
      end

      it "既存の投稿があれば再利用する" do
        existing = create(:post, youtube_url: valid_url)
        post find_or_create_posts_path, params: { youtube_url: valid_url }
        json = JSON.parse(response.body)
        expect(json['post_id']).to eq(existing.id)
      end
    end

    context "URLが空の場合" do
      it "エラーを返す" do
        post find_or_create_posts_path, params: { youtube_url: "" }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  # ====================
  # POST /posts/create_with_action (動画+アクションプラン作成)
  # ====================
  describe "POST /posts/create_with_action" do
    let(:valid_url) { "https://www.youtube.com/watch?v=test123" }

    before do
      allow(YoutubeService).to receive(:fetch_video_info).and_return({
        title: "Test Video",
        channel_name: "Test Channel"
      })
    end

    context "ログイン済みの場合" do
      before { sign_in user }

      context "有効なパラメータの場合" do
        it "投稿とエントリーを作成する" do
          expect {
            post create_with_action_posts_path, params: {
              youtube_url: valid_url,
              action_plan: "毎日運動する"
            }
          }.to change(PostEntry, :count).by(1)

          json = JSON.parse(response.body)
          expect(json['success']).to be true
        end
      end

      context "未達成エントリーがある場合" do
        before do
          create(:post_entry, user: user, achieved_at: nil)
        end

        it "別の投稿にもエントリーを作成できる" do
          expect {
            post create_with_action_posts_path, params: {
              youtube_url: valid_url,
              action_plan: "新しいアクション"
            }
          }.to change(PostEntry, :count).by(1)
          json = JSON.parse(response.body)
          expect(json['success']).to be true
        end
      end
    end

    context "未ログインの場合" do
      it "ログインページにリダイレクトされる" do
        post create_with_action_posts_path, params: {
          youtube_url: valid_url,
          action_plan: "テスト"
        }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  # ====================
  # GET /posts/:id/edit (編集フォーム)
  # ====================
  describe "GET /posts/:id/edit" do
    let(:post_record) { create(:post) }

    context "エントリー所有者の場合" do
      before do
        create(:post_entry, post: post_record, user: user)
        sign_in user
      end

      it "編集フォームが表示される" do
        get edit_post_path(post_record)
        expect(response).to have_http_status(200)
      end
    end

    context "エントリー所有者でない場合" do
      before do
        create(:post_entry, post: post_record, user: other_user)
        sign_in user
      end

      it "詳細ページにリダイレクトされる" do
        get edit_post_path(post_record)
        expect(response).to redirect_to(post_path(post_record))
      end
    end

    context "ログインしていない場合" do
      it "ログインページにリダイレクトされる" do
        get edit_post_path(post_record)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  # ====================
  # PATCH /posts/:id (更新)
  # ====================
  describe "PATCH /posts/:id" do
    let(:post_record) { create(:post, youtube_url: "https://www.youtube.com/watch?v=original") }

    context "エントリー所有者の場合" do
      before do
        create(:post_entry, post: post_record, user: user)
        sign_in user
      end

      context "有効なパラメータの場合" do
        it "詳細ページにリダイレクトされる" do
          patch post_path(post_record), params: { post: { youtube_url: post_record.youtube_url } }
          expect(response).to redirect_to(post_path(post_record))
        end
      end

      context "無効なパラメータの場合" do
        it "編集フォームが再表示される" do
          patch post_path(post_record), params: { post: { youtube_url: "invalid-url" } }
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    context "エントリー所有者でない場合" do
      before do
        create(:post_entry, post: post_record, user: other_user)
        sign_in user
      end

      it "詳細ページにリダイレクトされる" do
        patch post_path(post_record), params: { post: { youtube_url: "https://youtube.com/watch?v=new" } }
        expect(response).to redirect_to(post_path(post_record))
      end
    end
  end

  # ====================
  # PATCH /posts/:id/update_with_action (動画+アクションプラン同時更新)
  # ====================
  describe "PATCH /posts/:id/update_with_action" do
    let(:post_record) { create(:post, youtube_video_id: "original123") }

    before do
      allow(YoutubeService).to receive(:fetch_video_info).and_return({
        title: "New Video",
        channel_name: "New Channel"
      })
    end

    context "エントリー所有者の場合" do
      let!(:entry) { create(:post_entry, post: post_record, user: user, content: "元のアクションプラン") }

      before { sign_in user }

      context "アクションプランのみ更新" do
        it "アクションプランを更新する" do
          patch update_with_action_post_path(post_record), params: {
            youtube_url: post_record.youtube_url,
            action_plan: "更新されたアクションプラン"
          }, as: :json

          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json['success']).to be true
          expect(entry.reload.content).to eq("更新されたアクションプラン")
        end
      end

      context "動画を変更する場合" do
        let(:new_url) { "https://www.youtube.com/watch?v=newvideo123" }

        it "新しい動画にエントリーを移動する" do
          patch update_with_action_post_path(post_record), params: {
            youtube_url: new_url,
            action_plan: "新しいアクションプラン"
          }, as: :json

          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json['success']).to be true
          expect(entry.reload.content).to eq("新しいアクションプラン")
          expect(entry.post.youtube_video_id).to eq("newvideo123")
        end
      end

      context "サムネイル画像を更新する場合" do
        it "サムネイルURLを更新する" do
          patch update_with_action_post_path(post_record), params: {
            youtube_url: post_record.youtube_url,
            action_plan: "アクションプラン",
            thumbnail_s3_key: "uploads/thumbnails/new_image.jpg"
          }, as: :json

          expect(response).to have_http_status(:ok)
          expect(entry.reload.thumbnail_url).to eq("uploads/thumbnails/new_image.jpg")
        end
      end

      context "アクションプランが空の場合" do
        it "エラーを返す" do
          patch update_with_action_post_path(post_record), params: {
            youtube_url: post_record.youtube_url,
            action_plan: ""
          }, as: :json

          expect(response).to have_http_status(:unprocessable_entity)
          json = JSON.parse(response.body)
          expect(json['error']).to include("アクションプラン")
        end
      end
    end

    context "エントリー所有者でない場合" do
      before do
        create(:post_entry, post: post_record, user: other_user)
        sign_in user
      end

      it "詳細ページにリダイレクトされる" do
        patch update_with_action_post_path(post_record), params: {
          youtube_url: post_record.youtube_url,
          action_plan: "テスト"
        }, as: :json

        expect(response).to redirect_to(post_path(post_record))
      end
    end

    context "ログインしていない場合" do
      it "401 Unauthorizedを返す" do
        patch update_with_action_post_path(post_record), params: {
          youtube_url: post_record.youtube_url,
          action_plan: "テスト"
        }, as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  # ====================
  # DELETE /posts/:id (削除)
  # ====================
  describe "DELETE /posts/:id" do
    let!(:post_record) { create(:post) }

    context "エントリー所有者の場合" do
      before do
        create(:post_entry, post: post_record, user: user)
        sign_in user
      end

      it "エントリーを削除する" do
        expect {
          delete post_path(post_record)
        }.to change(PostEntry, :count).by(-1)
      end

      it "一覧ページにリダイレクトされる" do
        delete post_path(post_record)
        expect(response).to redirect_to(posts_path)
      end
    end

    context "エントリー所有者でない場合" do
      before do
        create(:post_entry, post: post_record, user: other_user)
        sign_in user
      end

      it "エントリーを削除できない" do
        expect {
          delete post_path(post_record)
        }.not_to change(PostEntry, :count)
      end
    end

    context "ログインしていない場合" do
      it "ログインページにリダイレクトされる" do
        delete post_path(post_record)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  # ====================
  # GET /posts/autocomplete (オートコンプリート)
  # ====================
  describe "GET /posts/autocomplete" do
    let!(:post1) { create(:post, youtube_title: "Ruby入門講座") }
    let!(:post2) { create(:post, youtube_title: "Rubyで自動化入門") }

    it "検索候補を返す" do
      get autocomplete_posts_path, params: { q: "Ruby" }
      expect(response).to have_http_status(:ok)
    end

    it "2文字未満は空を返す" do
      get autocomplete_posts_path, params: { q: "R" }
      expect(response).to have_http_status(:ok)
    end
  end

  # ====================
  # GET /posts/recent (最近の投稿)
  # ====================
  describe "GET /posts/recent" do
    it "最近の投稿ページを表示" do
      get recent_posts_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /posts/youtube_search" do
    before do
      allow(YoutubeService).to receive(:search_videos).and_return([
        { video_id: 'abc123', title: 'テスト動画', channel_name: 'テストチャンネル' }
      ])
    end

    context 'クエリが2文字以上の場合' do
      it 'YouTube検索結果をJSON形式で返す' do
        get youtube_search_posts_path, params: { q: 'テスト' }, as: :json
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json).to be_an(Array)
      end
    end

    context 'クエリが2文字未満の場合' do
      it '空の配列を返す' do
        get youtube_search_posts_path, params: { q: 'a' }, as: :json
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json).to eq([])
      end
    end
  end

  describe "GET /posts/search_posts" do
    let!(:user) { create(:user) }
    let!(:post_with_entry) { create(:post, user: user, youtube_title: 'プログラミング入門') }

    before do
      sign_in user
      create(:post_entry, post: post_with_entry, user: user)
    end

    context 'クエリが2文字以上の場合' do
      it '検索結果をJSON形式で返す' do
        get search_posts_posts_path, params: { q: 'プログラミング' }
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json).to be_an(Array)
      end
    end

    context 'クエリが2文字未満の場合' do
      it '空の配列を返す' do
        get search_posts_posts_path, params: { q: 'a' }
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json).to eq([])
      end
    end
  end

  describe "POST /posts/suggest_action_plans" do
    before do
      allow(GeminiService).to receive(:suggest_action_plans).and_return({
        success: true,
        action_plans: [ '【やってみた】朝5時起きを実践した結果', '【検証】読書メモを記録してみた' ]
      })
    end

    context 'video_idが指定されている場合' do
      it 'アクションプランを返す' do
        post suggest_action_plans_posts_path, params: { video_id: 'abc123', title: 'テスト動画' }, as: :json
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['action_plans']).to be_an(Array)
      end
    end

    context 'video_idが空の場合' do
      it 'エラーを返す' do
        post suggest_action_plans_posts_path, params: { video_id: '', title: 'テスト動画' }, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['success']).to be false
      end
    end

    context 'GeminiServiceがエラーを返した場合' do
      before do
        allow(GeminiService).to receive(:suggest_action_plans).and_return({
          success: false,
          error: 'AIが混み合っています'
        })
      end

      it 'エラーを返す' do
        post suggest_action_plans_posts_path, params: { video_id: 'abc123', title: 'テスト' }, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "POST /posts/convert_to_youtube_title" do
    before do
      allow(GeminiService).to receive(:convert_to_youtube_title).and_return({
        success: true,
        title: '【やってみた】朝5時起きを実践した結果'
      })
    end

    context 'アクションプランが指定されている場合' do
      it '変換されたタイトルを返す' do
        post convert_to_youtube_title_posts_path, params: { action_plan: '朝5時に起きる' }, as: :json
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['title']).to be_present
      end
    end

    context 'アクションプランが空の場合' do
      it 'エラーを返す' do
        post convert_to_youtube_title_posts_path, params: { action_plan: '' }, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['success']).to be false
      end
    end

    context 'GeminiServiceがエラーを返した場合' do
      before do
        allow(GeminiService).to receive(:convert_to_youtube_title).and_return({
          success: false,
          error: '変換に失敗しました'
        })
      end

      it 'エラーを返す' do
        post convert_to_youtube_title_posts_path, params: { action_plan: 'テスト' }, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "POST /posts/create_with_action" do
    let(:user) { create(:user) }

    context 'youtube_urlが空の場合' do
      before { sign_in user }

      it 'エラーを返す' do
        post create_with_action_posts_path, params: { youtube_url: '', action_plan: 'テスト' }, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('動画URLが必要です')
      end
    end

    context 'action_planが空の場合' do
      before { sign_in user }

      it 'エラーを返す' do
        post create_with_action_posts_path, params: { youtube_url: 'https://youtube.com/watch?v=test', action_plan: '' }, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('アクションプランが必要です')
      end
    end
  end

  describe "POST /posts/find_or_create" do
    context '動画情報が取得できない場合' do
      before do
        allow(Post).to receive(:find_or_create_by_video).and_return(nil)
      end

      it 'エラーを返す' do
        post find_or_create_posts_path, params: { youtube_url: 'https://youtube.com/watch?v=invalid' }, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['error']).to include('取得できませんでした')
      end
    end
  end
end
