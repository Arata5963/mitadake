# app/models/user.rb
# ==========================================
# ユーザー（アプリを使う人）
# ==========================================
#
# 【このモデルの役割】
# アプリにログインする人の情報を管理する。
# メールアドレス/パスワードでの登録と、Googleアカウントでのログインに対応。
#
# 【データベースのカラム（主要なもの）】
# - email: メールアドレス（ログインに使用）
# - encrypted_password: 暗号化されたパスワード
# - name: 表示名
# - avatar: プロフィール画像（S3に保存）
# - provider: 認証プロバイダ（"google_oauth2" など）
# - uid: プロバイダでのユーザーID
# - favorite_quote: お気に入りの言葉
# - favorite_quote_url: その言葉が出てくるYouTube動画のURL
#
# 【他のモデルとの関係】
#
#   User（あなた）
#     │
#     ├─ has_many :posts（投稿した動画）
#     │    └─ 自分が最初に登録した動画
#     │
#     ├─ has_many :post_entries（作成したアクションプラン）
#     │    └─ 「この動画を見て○○をやる！」という宣言
#     │
#     └─ has_many :entry_likes（押したいいね）
#          └─ 他の人のアクションプランへの応援
#
# 【ユーザー削除時の挙動】
# dependent: :destroy により、ユーザーを削除すると
# 関連する posts, post_entries, entry_likes も全て削除される
#
class User < ApplicationRecord

  # ==========================================
  # Devise（認証ライブラリ）の設定
  # ==========================================
  # Deviseは Rails で最も使われる認証ライブラリ。
  # 以下のモジュールを有効化している：
  #
  # - database_authenticatable: DBにパスワードを保存して認証
  # - registerable: ユーザー登録機能
  # - recoverable: パスワードリセット機能
  # - rememberable: 「ログイン状態を保持」機能
  # - validatable: メール/パスワードのバリデーション
  # - omniauthable: Google等の外部サービスでログイン
  #
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [ :google_oauth2 ]

  # ==========================================
  # アソシエーション（他テーブルとの関連）
  # ==========================================
  #
  # 【has_many とは？】
  # 「1対多」の関係を表す。1人のユーザーは複数の投稿を持てる。
  #
  # 【dependent: :destroy とは？】
  # 親（User）が削除されたら、子（posts等）も一緒に削除する。
  # これがないと、ユーザー削除後に「持ち主のいないデータ」が残ってしまう。
  #
  has_many :posts, dependent: :destroy
  has_many :entry_likes, dependent: :destroy
  has_many :post_entries, dependent: :destroy

  # ==========================================
  # ファイルアップロード（CarrierWave）
  # ==========================================
  # avatar カラムに ImageUploader を紐づける。
  # これにより user.avatar で画像のアップロード/取得ができる。
  #
  # 使用例:
  #   user.avatar = params[:avatar]  # アップロード
  #   user.avatar.url                # 画像URLを取得
  #   user.avatar.thumb.url          # サムネイルURLを取得
  #
  mount_uploader :avatar, ImageUploader

  # ==========================================
  # バリデーション（データの検証ルール）
  # ==========================================
  #
  # 【validates :name, presence: true】
  # 名前は必須。空だと保存できない。
  #
  validates :name, presence: true

  # 【お気に入りの言葉】
  # 50文字まで。空でもOK（allow_blank: true）
  validates :favorite_quote, length: { maximum: 50 }, allow_blank: true

  # 【お気に入りの言葉の動画URL】
  # YouTube URLの形式チェック。空でもOK。
  # 正規表現で「youtube.com/watch?v=」または「youtu.be/」を含むかチェック
  validates :favorite_quote_url, format: {
    with: %r{\A(https?://)?(www\.)?(youtube\.com/watch\?v=|youtu\.be/)[\w-]+(\?.*)?(?:#.*)?\z},
    message: "は有効なYouTube URLを入力してください"
  }, allow_blank: true

  # 【カスタムバリデーション】
  # 「お気に入りの言葉」と「動画URL」は両方入力するか、両方空にする必要がある
  validate :favorite_quote_consistency

  # ==========================================
  # クラスメソッド（User.メソッド名 で呼ぶ）
  # ==========================================

  # ------------------------------------------
  # 達成数ランキングを取得
  # ------------------------------------------
  # 【何をするメソッド？】
  # アクションプランを達成した数が多い順にユーザーを取得する。
  # トップページのランキング表示に使用。
  #
  # 【引数】
  # - limit: 何人取得するか（デフォルト10人）
  # - period: 集計期間（:all=全期間, :today=今日, :week=今週, :month=今月）
  #
  # 【戻り値】
  # ユーザーの配列。各ユーザーには achieved_count という追加属性がつく。
  #
  # 【使用例】
  #   User.by_achieved_count(limit: 5)
  #   #=> [#<User achieved_count=10>, #<User achieved_count=8>, ...]
  #
  # 【SQLの解説】
  # 1. users と post_entries をJOIN（結合）
  # 2. achieved_at が入っている（＝達成済み）レコードだけ抽出
  # 3. ユーザーIDでグループ化
  # 4. 各グループの件数をカウントして多い順にソート
  #
  def self.by_achieved_count(limit: 10, period: :all)
    scope = User
      .joins(:post_entries)                              # post_entriesテーブルと結合
      .where.not(post_entries: { achieved_at: nil })     # 達成済みのみ

    scope = apply_period_filter(scope, period)           # 期間フィルター適用

    scope
      .group("users.id")                                 # ユーザーごとにまとめる
      .order(Arel.sql("COUNT(post_entries.id) DESC"))    # 件数が多い順
      .limit(limit)                                      # 指定件数まで
      .select("users.*, COUNT(post_entries.id) AS achieved_count")  # 件数も取得
  end

  # ------------------------------------------
  # Googleログイン処理
  # ------------------------------------------
  # 【何をするメソッド？】
  # Googleでログインした時に呼ばれる。
  # 既存ユーザーを探すか、新規作成する。
  #
  # 【処理の流れ】
  # 1. すでにGoogle連携済みのユーザーを探す → 見つかればそれを返す
  # 2. 同じメールアドレスのユーザーを探す → 見つかればGoogle情報を追加
  # 3. どちらもなければ新規ユーザーを作成
  #
  # 【引数】
  # - auth: Googleから受け取った認証情報
  #   - auth.provider: "google_oauth2"
  #   - auth.uid: Googleでの一意のID
  #   - auth.info.email: メールアドレス
  #   - auth.info.name: 名前
  #
  def self.from_omniauth(auth)
    # ステップ1: すでにGoogle連携済みのユーザーを探す
    # provider（google_oauth2）と uid の組み合わせで検索
    user = find_by(provider: auth.provider, uid: auth.uid)
    return user if user

    # ステップ2: 同じメールの既存ユーザーを探す
    # メール/パスワードで登録済みの人が後からGoogleログインした場合
    user = find_by(email: auth.info.email)
    if user
      # Google情報を追加して連携
      user.update!(provider: auth.provider, uid: auth.uid)
      # 名前が空なら、Googleの名前をセット
      user.update!(name: auth.info.name) if user.name.blank? && auth.info.name.present?
      return user
    end

    # ステップ3: 完全に新規のユーザーを作成
    create!(
      email:    auth.info.email,
      name:     auth.info.name,
      password: Devise.friendly_token[0, 20],  # ランダムなパスワードを生成
      provider: auth.provider,
      uid:      auth.uid
    )
  end

  # ==========================================
  # インスタンスメソッド（user.メソッド名 で呼ぶ）
  # ==========================================

  # ------------------------------------------
  # 現在取り組み中のアクションプランを取得
  # ------------------------------------------
  # 【何をするメソッド？】
  # ユーザーが今やろうとしている（まだ達成していない）アクションプランを返す。
  #
  # 【重要なルール】
  # このアプリでは「1人につき未達成のアクションプランは1つだけ」というルールがある。
  # なので first で1件だけ取得すればOK。
  #
  # 【戻り値】
  # - PostEntry: 未達成のアクションプランがある場合
  # - nil: 全て達成済み、またはアクションプランがない場合
  #
  def current_action_plan
    post_entries.not_achieved.first
  end

  # ------------------------------------------
  # 現在取り組み中の動画を取得
  # ------------------------------------------
  # 【何をするメソッド？】
  # 現在のアクションプランの元になっている動画を返す。
  #
  # 【&. とは？】
  # 「ぼっち演算子」と呼ばれる。
  # current_action_plan が nil の場合、エラーにならずに nil を返す。
  #
  # 通常の書き方:
  #   if current_action_plan
  #     current_action_plan.post
  #   else
  #     nil
  #   end
  #
  # &. を使った書き方:
  #   current_action_plan&.post
  #
  def current_video
    current_action_plan&.post
  end

  private

  # ==========================================
  # プライベートメソッド（外部から呼べない）
  # ==========================================

  # ------------------------------------------
  # 期間フィルターを適用
  # ------------------------------------------
  # 【何をするメソッド？】
  # by_achieved_count で使用。
  # 期間（今日/今週/今月）に応じてWHERE句を追加する。
  #
  # 【Rubyの範囲オブジェクト】
  # Time.current.beginning_of_day.. は「今日の0時から現在まで」を表す。
  # 終わりを省略すると「〜以降」という意味になる。
  #
  def self.apply_period_filter(scope, period)
    case period.to_sym
    when :today
      # 今日の0時以降に達成したもの
      scope.where(post_entries: { achieved_at: Time.current.beginning_of_day.. })
    when :week
      # 今週の月曜0時以降に達成したもの
      scope.where(post_entries: { achieved_at: Time.current.beginning_of_week.. })
    when :month
      # 今月の1日0時以降に達成したもの
      scope.where(post_entries: { achieved_at: Time.current.beginning_of_month.. })
    else
      # :all の場合はフィルターなし
      scope
    end
  end

  # ------------------------------------------
  # お気に入りの言葉と動画URLの整合性チェック
  # ------------------------------------------
  # 【何をするメソッド？】
  # 「お気に入りの言葉」と「動画URL」は、
  # 両方入力するか、両方空にする必要がある。
  # 片方だけ入力されていたらエラーにする。
  #
  # 【なぜこのルールがあるか？】
  # 言葉だけあって動画がない、または動画だけあって言葉がない状態は
  # ユーザー体験として中途半端なため。
  #
  def favorite_quote_consistency
    quote_present = favorite_quote.present?  # 言葉が入力されているか
    url_present = favorite_quote_url.present?  # URLが入力されているか

    # 片方だけ入力されていたらエラー
    if quote_present != url_present
      errors.add(:base, "すきな言葉と動画URLは両方入力するか、両方空にしてください")
    end
  end
end
