# mitadake? - Claude Code 開発ガイド

このファイルはClaude Codeがプロジェクト全体を理解し、一貫性のある開発を行うための統括ドキュメントです。

## プロジェクト概要

- **プロジェクト名**: mitadake?（みただけ？）
- **概要**: YouTube動画から学びを行動に変えるプラットフォーム
- **技術スタック**: Ruby on Rails 7.2.2 / PostgreSQL / Hotwire / Tailwind CSS

## クイックリファレンス

### タスク別ドキュメントマップ

| タスク | 参照ドキュメント |
|--------|------------------|
| 新機能の実装 | `01_technical_design/01_architecture.md`, `01_technical_design/02_database.md` |
| API実装 | `01_technical_design/03_api_design.md` |
| 画面実装 | `01_technical_design/04_screen_flow.md`, `02_design_system/` |
| テスト作成 | `01_technical_design/08_test_strategy.md` |
| スタイリング | `02_design_system/01_design_tokens.md`, `02_design_system/03_components.md` |
| Devise関連 | `03_library_guides/01_devise.md` |
| Hotwire実装 | `03_library_guides/02_hotwire.md` |
| 検索機能 | `03_library_guides/03_ransack.md` |
| 画像アップロード | `03_library_guides/04_carrierwave.md` |
| バックグラウンドジョブ | `03_library_guides/05_sidekiq.md` |
| Git操作・PR作成 | `01_technical_design/10_git_workflow.md` |
| 設計決定の記録 | `04_adr/` |

## ドキュメント構成

```
.claude/
├── 00_project/
│   └── 01_appcadia_concept_requirements.md  # コンセプト・要件定義
├── 01_technical_design/
│   ├── 01_architecture.md                   # アーキテクチャ設計
│   ├── 02_database.md                       # データベース設計
│   ├── 03_api_design.md                     # API設計
│   ├── 04_screen_flow.md                    # 画面遷移
│   ├── 05_error_handling.md                 # エラーハンドリング
│   ├── 06_security.md                       # セキュリティ
│   ├── 07_performance.md                    # パフォーマンス
│   ├── 08_test_strategy.md                  # テスト戦略
│   ├── 09_ci_cd.md                          # CI/CD
│   └── 10_git_workflow.md                   # Gitワークフロー
├── 02_design_system/
│   ├── 01_design_tokens.md                  # カラー、余白、角丸、影
│   ├── 02_design_principles.md              # デザイン原則、方針
│   ├── 03_components.md                     # UIコンポーネント設計
│   └── 04_layouts.md                        # レイアウトシステム
├── 03_library_guides/
│   ├── 01_devise.md                         # Devise実装パターン
│   ├── 02_hotwire.md                        # Hotwire実装パターン
│   ├── 03_ransack.md                        # Ransack実装パターン
│   ├── 04_carrierwave.md                    # CarrierWave実装パターン
│   └── 05_sidekiq.md                        # Sidekiq実装パターン
├── 04_adr/                                   # ADR（設計決定記録）
│   └── ADR-YYYYMMDD-xxx.md
└── 05_learning/                              # 学習記録
    └── YYYY-MM-DD-xxx.md
```

## 開発時の基本ルール

### コーディング規約

1. **Ruby**: RuboCopに従う（`.rubocop.yml`参照）
2. **命名規則**:
   - Model/Controller: CamelCase
   - メソッド/変数: snake_case
   - 定数: SCREAMING_SNAKE_CASE

### コメントガイドライン

**ファイルヘッダー（2行）**
- 1行目: 役割（何をするか）
- 2行目: いつ・どう使われるか
- ファイル名は書かない（見ればわかる）
- 区切り線（`====`や`----`）は使わない

**メソッドコメント**
- メソッドの上に1行コメントを追加（何をするか）

**横コメント**
- 全ての行につける（見落とし防止のため）
- 同じブロック内は `#` の位置を揃える
- 異なるブロック間は揃えなくてよい
- WHY（なぜ）や注意点も横コメントで書く

**Ruby例:**
```ruby
# YouTube動画モデル
# ユーザーが登録した動画を管理する

class Post < ApplicationRecord
  belongs_to :user, optional: true                     # 投稿者（任意）
  has_many :post_entries, dependent: :destroy          # アクションプラン一覧

  validates :youtube_url, presence: true               # URL必須

  # DBの値またはURLから動画IDを取得
  def youtube_video_id
    read_attribute(:youtube_video_id) || extract(url)  # read_attribute使用: selfだと無限ループ
  end
end
```

**JavaScript例:**
```javascript
// 達成カードコントローラー
// カードクリック時に達成記録モーダルを開く

import { Controller } from "@hotwired/stimulus"  // Stimulusコントローラー基底クラス

export default class extends Controller {
  static values = {
    entryId: Number,                             // エントリーID
    mode: { type: String, default: "display" }   // モード（input/display）
  }

  // カードクリック時にモーダルを開く
  async open(event) {
    event.preventDefault()                       // デフォルト動作を防止
    event.stopPropagation()                      // イベント伝播を停止
  }
}
```

**YAML例:**
```yaml
# Render.com インフラ設定（IaC）
# GitHubにpushすると自動でサーバー・DBが構築される

databases:
  - name: mitadake-postgres              # Renderで表示される名前
    plan: free                           # 無料プラン（90日で自動削除に注意）
```

**書かなくて良いコメント:** コードの直訳、パラメータ説明、使用例、変更履歴、TODO

### Git運用

- **ブランチ戦略**: GitHub Flow
  - `main`: 本番環境
  - `feature/*`: 機能開発
  - `fix/*`: バグ修正
- **コミットメッセージ**: 日本語可、Conventional Commits推奨
  - `feat:` 新機能
  - `fix:` バグ修正
  - `refactor:` リファクタリング
  - `test:` テスト
  - `docs:` ドキュメント
- **重要**: コミット・プッシュ・PR作成の前に必ずユーザーの確認を取ること

### テスト

- **テストフレームワーク**: RSpec
- **カバレッジ目標**: 80%以上
- **必須テスト**:
  - Model: バリデーション、アソシエーション、スコープ
  - Controller: 各アクション、認証・認可
  - System: 主要ユーザーフロー

### セキュリティ

- 必ず`current_user`スコープを使用
- Strong Parametersを適切に設定
- Brakemanの警告をゼロに保つ

## 頻出コマンド

```bash
# 開発サーバー起動
docker compose up

# テスト実行
docker compose exec web rspec

# RuboCop実行
docker compose exec web rubocop

# マイグレーション
docker compose exec web rails db:migrate

# コンソール
docker compose exec web rails c
```

## 重要ファイルパス

| 種類 | パス |
|------|------|
| ルーティング | `config/routes.rb` |
| モデル | `app/models/` |
| コントローラー | `app/controllers/` |
| ビュー | `app/views/` |
| Stimulus | `app/javascript/controllers/` |
| スタイル | `app/assets/stylesheets/` |
| テスト | `spec/` |
| 国際化 | `config/locales/` |

## 注意事項

- 実装前に必ず関連ドキュメントを参照すること
- スタイリングは`02_design_system/`のデザイントークン・コンポーネントに従うこと
- Tailwind CSSのユーティリティクラスを使用すること
- 新規機能は必ずテストを作成すること
- セキュリティ関連の実装は`01_technical_design/06_security.md`を必ず参照

## 機能実装完了時のチェックリスト

機能実装が完了したら、以下の手順を実行してください：

### 1. ドキュメント整合性チェック

以下のドキュメントが実際のプロジェクトと一致しているか確認：

| 変更内容 | 確認すべきドキュメント |
|----------|----------------------|
| DBスキーマ変更 | `01_technical_design/02_database.md` |
| 新モデル/コントローラー追加 | `01_technical_design/01_architecture.md` |
| 新ライブラリ導入 | `03_library_guides/` に新規ガイド作成 |
| 大きな設計判断 | `04_adr/` にADR作成 |

### 2. Gitフロー実行

`01_technical_design/10_git_workflow.md` に従ってコミット・PR作成

### Claude Code への依頼テンプレート

```
<機能名>の実装が完了しました。以下を実行してください：
1. .claude/ ドキュメントと実際のプロジェクトの整合性をチェック
2. 必要に応じてドキュメントを更新
3. 10_git_workflow.md に従ってGitフローを実行
ブランチ名: feature/<機能名>
```

## PR作成ルール

PRを作成する際は以下のルールに従うこと：

### テンプレート形式

- セクション名は日本語で記載
  - 概要（Summaryではない）
  - 変更内容（Changesではない）
  - テスト方法（Test planではない）
- `🤖 Generated with Claude Code` のフッターは付けない

### 例

```
## 概要
YouTube埋め込み対応

## 変更内容
- `app/models/post.rb`: youtube_embed_url メソッド追加
- `app/views/posts/index.html.erb`: iframe埋め込みに変更

## テスト方法
1. 投稿一覧ページでYouTube動画がiframeで表示されることを確認
2. RSpecテストがパスすること
```

---

*最終更新: 2026-01-26*
