# テスト戦略

## 基本方針

- **テストフレームワーク**: RSpec
- **カバレッジ目標**: 80%以上
- **CI**: GitHub Actionsで自動実行

## テストの種類

### モデルテスト（spec/models/）

- バリデーション
- アソシエーション
- スコープ
- インスタンスメソッド

```ruby
RSpec.describe PostEntry, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:content) }
  end

  describe 'associations' do
    it { should belong_to(:post) }
    it { should belong_to(:user) }
  end

  describe '#achieved?' do
    it 'returns true when achieved_at is present' do
      entry = build(:post_entry, :achieved)
      expect(entry.achieved?).to be true
    end
  end
end
```

### リクエストテスト（spec/requests/）

- 各エンドポイントの動作
- 認証・認可
- レスポンス形式

```ruby
RSpec.describe 'PostEntries', type: :request do
  describe 'POST /posts/:post_id/post_entries' do
    context 'when logged in' do
      before { sign_in user }

      it 'creates a new entry' do
        expect {
          post post_post_entries_path(post_record), params: valid_params
        }.to change(PostEntry, :count).by(1)
      end
    end
  end
end
```

### サービステスト（spec/services/）

- 外部API連携のモック
- 正常系・異常系

```ruby
RSpec.describe GeminiService do
  describe '.suggest_action_plans' do
    before do
      stub_request(:post, /generativelanguage.googleapis.com/)
        .to_return(status: 200, body: success_response.to_json)
    end

    it 'returns action plan suggestions' do
      result = described_class.suggest_action_plans(...)
      expect(result[:success]).to be true
    end
  end
end
```

## テスト実行

```bash
# 全テスト実行
docker compose exec web rspec

# 特定ファイル
docker compose exec web rspec spec/models/post_entry_spec.rb

# カバレッジレポート生成
docker compose exec web rspec
# coverage/index.html を確認
```

## モックとスタブ

- **WebMock**: 外部HTTP通信のモック
- **FactoryBot**: テストデータ生成

```ruby
# spec/rails_helper.rb
require 'webmock/rspec'
WebMock.disable_net_connect!(allow_localhost: true)
```

## テスト作成の指針

1. 新機能追加時は必ずテストを書く
2. バグ修正時は再発防止テストを追加
3. 外部APIは必ずモック化
4. エッジケースを考慮
