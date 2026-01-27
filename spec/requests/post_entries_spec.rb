# PostEntries コントローラーのリクエストテスト
# アクションプランのCRUD、達成、いいね機能を検証

require 'rails_helper'

RSpec.describe 'PostEntries', type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:post_record) { create(:post) }

  describe 'POST /posts/:post_id/post_entries' do
    context 'when logged in' do
      before { sign_in user }

      context 'with valid params' do
        let(:valid_params) do
          {
            post_entry: {
              content: '毎日30分運動する',
              deadline: Date.current + 7.days
            }
          }
        end

        it 'creates a new entry' do
          expect {
            post post_post_entries_path(post_record), params: valid_params
          }.to change(PostEntry, :count).by(1)
        end

        it 'redirects to post with success message' do
          post post_post_entries_path(post_record), params: valid_params
          expect(response).to redirect_to(post_record)
          follow_redirect!
          expect(response.body).to include('アクションプランを投稿しました')
        end

        it 'sets the current user as entry owner' do
          post post_post_entries_path(post_record), params: valid_params
          expect(PostEntry.last.user).to eq(user)
        end
      end

      context 'with invalid params' do
        let(:invalid_params) do
          {
            post_entry: {
              content: '',  # required
              deadline: Date.current + 7.days
            }
          }
        end

        it 'does not create entry' do
          expect {
            post post_post_entries_path(post_record), params: invalid_params
          }.not_to change(PostEntry, :count)
        end

        it 'shows error message' do
          post post_post_entries_path(post_record), params: invalid_params
          expect(response).to redirect_to(post_record)
        end
      end

      context 'when user already has unachieved entry' do
        let(:other_post) { create(:post) }

        before do
          create(:post_entry, user: user, post: post_record, achieved_at: nil)
        end

        it 'allows creating another entry on a different post' do
          expect {
            post post_post_entries_path(other_post), params: {
              post_entry: { content: 'New action', deadline: Date.current + 7.days }
            }
          }.to change(PostEntry, :count).by(1)
        end
      end
    end

    context 'when not logged in' do
      it 'redirects to login page' do
        post post_post_entries_path(post_record), params: {
          post_entry: { content: 'Test', deadline: Date.current + 7.days }
        }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /posts/:post_id/post_entries/:id/edit' do
    let!(:entry) { create(:post_entry, user: user, post: post_record) }

    context 'when logged in as entry owner' do
      before { sign_in user }

      it 'renders edit form' do
        get edit_post_post_entry_path(post_record, entry)
        expect(response).to have_http_status(:success)
      end
    end

    context 'when logged in as different user' do
      before { sign_in other_user }

      it 'redirects with error message' do
        get edit_post_post_entry_path(post_record, entry)
        expect(response).to redirect_to(post_record)
      end
    end

    context 'when not logged in' do
      it 'redirects to login page' do
        get edit_post_post_entry_path(post_record, entry)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'PATCH /posts/:post_id/post_entries/:id' do
    let!(:entry) { create(:post_entry, user: user, post: post_record, content: 'Original content') }

    context 'when logged in as entry owner' do
      before { sign_in user }

      context 'with valid params' do
        it 'updates the entry' do
          patch post_post_entry_path(post_record, entry), params: {
            post_entry: { content: 'Updated content' }
          }
          expect(entry.reload.content).to eq('Updated content')
        end

        it 'redirects to post' do
          patch post_post_entry_path(post_record, entry), params: {
            post_entry: { content: 'Updated content' }
          }
          expect(response).to redirect_to(post_record)
        end
      end

      context 'with invalid params' do
        it 'does not update and returns error' do
          patch post_post_entry_path(post_record, entry), params: {
            post_entry: { content: '' }
          }
          expect(entry.reload.content).to eq('Original content')
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context 'with JSON format' do
        it 'returns JSON success response' do
          patch post_post_entry_path(post_record, entry),
                params: { post_entry: { content: 'Updated via JSON' } },
                headers: { 'Accept' => 'application/json' }
          expect(response).to have_http_status(:success)
          json = JSON.parse(response.body)
          expect(json['success']).to be true
        end

        it 'includes redirect_url for mypage' do
          patch post_post_entry_path(post_record, entry),
                params: { post_entry: { content: 'Updated' }, from: 'mypage' },
                headers: { 'Accept' => 'application/json' }
          json = JSON.parse(response.body)
          expect(json['redirect_url']).to eq(mypage_path)
        end

        context 'with invalid params' do
          it 'returns JSON error response' do
            patch post_post_entry_path(post_record, entry),
                  params: { post_entry: { content: '' } },
                  headers: { 'Accept' => 'application/json' }
            expect(response).to have_http_status(:unprocessable_entity)
            json = JSON.parse(response.body)
            expect(json['success']).to be false
          end
        end
      end

      context 'with thumbnail_s3_key CLEAR' do
        before { entry.update!(thumbnail_url: 'existing_url') }

        it 'clears the thumbnail' do
          patch post_post_entry_path(post_record, entry), params: {
            post_entry: { content: 'Updated', thumbnail_s3_key: 'CLEAR' }
          }
          expect(entry.reload.thumbnail_url).to be_nil
        end
      end

      context 'with thumbnail_s3_key present' do
        it 'sets the thumbnail URL' do
          patch post_post_entry_path(post_record, entry), params: {
            post_entry: { content: 'Updated', thumbnail_s3_key: 'uploads/new_image.jpg' }
          }
          expect(entry.reload.thumbnail_url).to eq('uploads/new_image.jpg')
        end
      end

      context 'with from=mypage' do
        it 'redirects to mypage' do
          patch post_post_entry_path(post_record, entry), params: {
            post_entry: { content: 'Updated' }, from: 'mypage'
          }
          expect(response).to redirect_to(mypage_path)
        end
      end
    end

    context 'when logged in as different user' do
      before { sign_in other_user }

      it 'does not update and redirects' do
        patch post_post_entry_path(post_record, entry), params: {
          post_entry: { content: 'Hacked content' }
        }
        expect(entry.reload.content).to eq('Original content')
        expect(response).to redirect_to(post_record)
      end
    end
  end

  describe 'DELETE /posts/:post_id/post_entries/:id' do
    let!(:entry) { create(:post_entry, user: user, post: post_record) }

    context 'when logged in as entry owner' do
      before { sign_in user }

      it 'deletes the entry' do
        expect {
          delete post_post_entry_path(post_record, entry)
        }.to change(PostEntry, :count).by(-1)
      end

      it 'redirects to post' do
        delete post_post_entry_path(post_record, entry)
        expect(response).to redirect_to(post_path(post_record, design: nil))
      end

      context 'with from=mypage' do
        it 'redirects to mypage' do
          delete post_post_entry_path(post_record, entry), params: { from: 'mypage' }
          expect(response).to redirect_to(mypage_path)
        end
      end

      context 'when referer includes mypage' do
        it 'redirects to mypage' do
          delete post_post_entry_path(post_record, entry),
                 headers: { 'HTTP_REFERER' => 'http://example.com/mypage' }
          expect(response).to redirect_to(mypage_path)
        end
      end
    end

    context 'when logged in as different user' do
      before { sign_in other_user }

      it 'does not delete and redirects' do
        expect {
          delete post_post_entry_path(post_record, entry)
        }.not_to change(PostEntry, :count)
        expect(response).to redirect_to(post_record)
      end
    end
  end

  describe 'PATCH /posts/:post_id/post_entries/:id/achieve' do
    let!(:entry) { create(:post_entry, user: user, post: post_record, achieved_at: nil) }

    context 'when logged in as entry owner' do
      before { sign_in user }

      context 'when not achieved' do
        it 'marks entry as achieved' do
          patch achieve_post_post_entry_path(post_record, entry)
          expect(entry.reload.achieved?).to be true
        end

        it 'shows success message' do
          patch achieve_post_post_entry_path(post_record, entry)
          expect(response).to redirect_to(post_path(post_record, design: nil))
          follow_redirect!
          expect(response.body).to include('達成おめでとうございます')
        end
      end

      context 'when already achieved' do
        before { entry.update!(achieved_at: Time.current) }

        it 'marks entry as not achieved' do
          patch achieve_post_post_entry_path(post_record, entry)
          expect(entry.reload.achieved?).to be false
        end
      end

      context 'with JSON format (modal submission)' do
        it 'returns JSON success response' do
          patch achieve_post_post_entry_path(post_record, entry),
                params: { reflection: '頑張りました！' },
                headers: { 'Accept' => 'application/json' }
          expect(response).to have_http_status(:success)
          json = JSON.parse(response.body)
          expect(json['success']).to be true
          expect(json['achieved']).to be true
        end

        it 'saves reflection' do
          patch achieve_post_post_entry_path(post_record, entry),
                params: { reflection: '頑張りました！' },
                headers: { 'Accept' => 'application/json' }
          expect(entry.reload.reflection).to eq('頑張りました！')
        end

        context 'when already achieved' do
          before { entry.update!(achieved_at: Time.current, reflection: 'Old reflection') }

          it 'marks as not achieved' do
            patch achieve_post_post_entry_path(post_record, entry),
                  headers: { 'Accept' => 'application/json' }
            expect(response).to have_http_status(:success)
            json = JSON.parse(response.body)
            expect(json['achieved']).to be false
            expect(entry.reload.achieved?).to be false
          end

          it 'clears reflection' do
            patch achieve_post_post_entry_path(post_record, entry),
                  headers: { 'Accept' => 'application/json' }
            expect(entry.reload.reflection).to be_nil
          end
        end
      end

      context 'with Turbo Stream format' do
        it 'marks entry as achieved' do
          patch achieve_post_post_entry_path(post_record, entry),
                params: { reflection: '達成しました！' },
                headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
          expect(response).to have_http_status(:success)
          expect(entry.reload.achieved?).to be true
        end

        context 'when already achieved' do
          before { entry.update!(achieved_at: Time.current, reflection: 'Old reflection') }

          it 'marks as not achieved' do
            patch achieve_post_post_entry_path(post_record, entry),
                  headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
            expect(entry.reload.achieved?).to be false
          end
        end
      end

      context 'with redirect_to=mypage' do
        it 'redirects to mypage' do
          patch achieve_post_post_entry_path(post_record, entry),
                params: { redirect_to: 'mypage' }
          expect(response).to redirect_to(mypage_path)
        end
      end

      context 'when referer includes mypage' do
        it 'redirects to mypage' do
          patch achieve_post_post_entry_path(post_record, entry),
                headers: { 'HTTP_REFERER' => 'http://example.com/mypage' }
          expect(response).to redirect_to(mypage_path)
        end
      end
    end

    context 'when logged in as different user' do
      before { sign_in other_user }

      it 'does not change achievement status' do
        expect {
          patch achieve_post_post_entry_path(post_record, entry)
        }.not_to change { entry.reload.achieved? }
        expect(response).to redirect_to(post_record)
      end
    end
  end

  describe 'GET /posts/:post_id/post_entries/:id/show_achievement' do
    let!(:entry) do
      create(:post_entry, :achieved, user: user, post: post_record,
             content: 'Test content', reflection: 'Good job!')
    end

    it 'returns JSON with achievement data' do
      get show_achievement_post_post_entry_path(post_record, entry),
          headers: { 'Accept' => 'application/json' }
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['content']).to eq('Test content')
      expect(json['reflection']).to eq('Good job!')
    end

    it 'works without authentication' do
      get show_achievement_post_post_entry_path(post_record, entry),
          headers: { 'Accept' => 'application/json' }
      expect(response).to have_http_status(:success)
    end
  end

  describe 'PATCH /posts/:post_id/post_entries/:id/update_reflection' do
    let!(:entry) { create(:post_entry, :achieved, user: user, post: post_record, reflection: 'Old reflection') }

    context 'when logged in as entry owner' do
      before { sign_in user }

      it 'updates reflection' do
        patch update_reflection_post_post_entry_path(post_record, entry),
              params: { reflection: 'New reflection' },
              headers: { 'Accept' => 'application/json' }
        expect(response).to have_http_status(:success)
        expect(entry.reload.reflection).to eq('New reflection')
      end
    end

    context 'when logged in as different user' do
      before { sign_in other_user }

      it 'does not update and redirects' do
        patch update_reflection_post_post_entry_path(post_record, entry),
              params: { reflection: 'Hacked reflection' }
        expect(entry.reload.reflection).to eq('Old reflection')
      end
    end
  end

  describe 'POST /posts/:post_id/post_entries/:id/toggle_like' do
    let!(:entry) { create(:post_entry, user: user, post: post_record) }

    context 'when logged in' do
      before { sign_in other_user }

      context 'when not liked' do
        it 'creates a like' do
          expect {
            post toggle_like_post_post_entry_path(post_record, entry)
          }.to change(EntryLike, :count).by(1)
        end
      end

      context 'when already liked' do
        before { EntryLike.create!(user: other_user, post_entry: entry) }

        it 'removes the like' do
          expect {
            post toggle_like_post_post_entry_path(post_record, entry)
          }.to change(EntryLike, :count).by(-1)
        end
      end
    end

    context 'when not logged in' do
      it 'redirects to login' do
        post toggle_like_post_post_entry_path(post_record, entry)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
