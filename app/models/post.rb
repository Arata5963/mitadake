# app/models/post.rb
# ==========================================
# YouTube動画（投稿された動画）
# ==========================================
#
# 【このモデルの役割】
# ユーザーが登録したYouTube動画を管理する。
# 1つの動画に対して、複数のユーザーがアクションプラン（PostEntry）を作成できる。
#
# 【データベースのカラム（主要なもの）】
# - youtube_url: YouTube動画のURL
# - youtube_video_id: YouTube動画ID（例: "dQw4w9WgXcQ"）
# - youtube_title: 動画のタイトル（API経由で自動取得）
# - youtube_channel_name: チャンネル名（API経由で自動取得）
# - youtube_channel_id: チャンネルID（API経由で自動取得）
# - youtube_channel_thumbnail_url: チャンネルのサムネイル画像URL
# - action_plan: 旧形式のアクションプラン（現在は未使用、互換性のため残存）
#
# 【他のモデルとの関係】
#
#   Post（YouTube動画）
#     │
#     ├─ belongs_to :user（投稿者）※optional
#     │    └─ 最初にこの動画を登録したユーザー
#     │       ただし、誰でも同じ動画にアクションプランを作成可能
#     │
#     └─ has_many :post_entries（アクションプラン）
#          └─ この動画を見て「○○をやる！」という宣言一覧
#
# 【重要な仕組み】
# - 同じ動画は1つのPostとして管理される（動画IDで重複チェック）
# - YouTube APIから動画情報を自動取得（タイトル、チャンネル名など）
#
class Post < ApplicationRecord

  # ==========================================
  # アソシエーション（他テーブルとの関連）
  # ==========================================
  #
  # 【belongs_to :user, optional: true とは？】
  # 通常の belongs_to は「必ず親が必要」だが、
  # optional: true をつけると「親がなくてもOK」になる。
  #
  # なぜoptionalにしているか？
  # → 後からアクションプランを追加するユーザーがいるため、
  #   最初の投稿者を必須にする意味がないから。
  #
  belongs_to :user, optional: true

  # 【has_many :post_entries とは？】
  # 1つの動画に複数のアクションプランが紐づく。
  #
  # dependent: :destroy により、動画を削除すると
  # 関連するアクションプランも全て削除される。
  #
  has_many :post_entries, dependent: :destroy

  # ==========================================
  # バリデーション（データの検証ルール）
  # ==========================================

  # YouTube URLは必須
  validates :youtube_url, presence: true

  # 【URL形式のバリデーション】
  # 正規表現を使って、有効なYouTube URLかチェック。
  #
  # 受け付ける形式:
  # - https://www.youtube.com/watch?v=動画ID
  # - https://youtube.com/watch?v=動画ID
  # - https://youtu.be/動画ID（短縮URL）
  #
  # 正規表現の解説:
  # - \A ... \z: 文字列の最初から最後まで
  # - (https?://)?: http:// または https:// （省略可）
  # - (www\.)?: www.（省略可）
  # - youtube\.com/watch\?v= : youtube.comの通常形式
  # - youtu\.be/: 短縮URL形式
  # - [\w-]+: 動画ID（英数字とハイフン）
  # - (\?.*)?(?:#.*)?: パラメータやフラグメント（省略可）
  #
  validates :youtube_url, format: {
    with: %r{\A(https?://)?(www\.)?(youtube\.com/watch\?v=|youtu\.be/)[\w-]+(\?.*)?(?:#.*)?\z},
    message: "は有効なYouTube URLを入力してください"
  }

  # 【旧形式のaction_plan】
  # 以前はPostに直接アクションプランを保存していたが、
  # 現在はPostEntry経由で管理している。
  # 既存データとの互換性のため残している。
  validates :action_plan, length: { maximum: 100 }, allow_blank: true

  # ==========================================
  # コールバック（保存前後に自動実行される処理）
  # ==========================================
  #
  # 【before_save とは？】
  # データベースに保存される直前に実行されるメソッド。
  #
  # 【if: :should_fetch_youtube_info? とは？】
  # 条件付きコールバック。should_fetch_youtube_info? が
  # true を返す場合のみ実行される。
  #
  # 実行タイミング:
  # - 新規作成時（new_record? が true）
  # - URLが変更された時（youtube_url_changed? が true）
  #
  before_save :set_youtube_video_id, if: :should_fetch_youtube_info?
  before_save :fetch_youtube_info, if: :should_fetch_youtube_info?

  # ==========================================
  # スコープ（よく使う検索条件をメソッド化）
  # ==========================================
  #
  # 【スコープとは？】
  # よく使う検索条件に名前をつけて再利用できるようにしたもの。
  #
  # 使用例:
  #   Post.recent           # 新しい順
  #   Post.with_entries     # アクションプラン付きのみ
  #   Post.recent.limit(10) # チェーン可能
  #

  # 新しい順に並べる
  scope :recent, -> { order(created_at: :desc) }

  # アクションプランが1つ以上ある動画のみ取得
  # distinct により重複を除去（JOINすると重複する可能性があるため）
  scope :with_entries, -> { joins(:post_entries).distinct }

  # ==========================================
  # Ransack設定（検索機能用）
  # ==========================================
  #
  # 【Ransackとは？】
  # 検索フォームを簡単に作れるRailsのgem。
  # セキュリティのため、検索可能な属性を明示的に指定する必要がある。
  #

  # 検索可能なカラムを指定
  # これらのカラムだけがRansack経由で検索できる
  def self.ransackable_attributes(_auth_object = nil)
    %w[action_plan youtube_title youtube_channel_name created_at]
  end

  # 検索で関連付けられるモデルを指定
  # user経由での検索を許可
  def self.ransackable_associations(_auth_object = nil)
    %w[user]
  end

  # ==========================================
  # YouTube関連メソッド
  # ==========================================

  # ------------------------------------------
  # YouTube動画IDを取得
  # ------------------------------------------
  # 【何をするメソッド？】
  # データベースに保存された動画IDを返す。
  # 保存されていなければ、URLから動的に抽出する。
  #
  # 【read_attribute とは？】
  # データベースのカラム値を直接読み取るメソッド。
  # 通常の属性アクセス（self.youtube_video_id）と違い、
  # 同名のメソッドがあっても上書きされない。
  #
  # 【|| とは？】
  # 左側がnilまたはfalseの場合、右側を返す。
  # 「AがなければBを使う」というパターン。
  #
  def youtube_video_id
    read_attribute(:youtube_video_id) || self.class.extract_video_id(youtube_url)
  end

  # ------------------------------------------
  # URLから動画IDを抽出（クラスメソッド）
  # ------------------------------------------
  # 【何をするメソッド？】
  # YouTube URLから動画IDを取り出す。
  #
  # 【使用例】
  #   Post.extract_video_id("https://www.youtube.com/watch?v=dQw4w9WgXcQ")
  #   #=> "dQw4w9WgXcQ"
  #
  #   Post.extract_video_id("https://youtu.be/dQw4w9WgXcQ")
  #   #=> "dQw4w9WgXcQ"
  #
  # 【処理の流れ】
  # 1. URLが空なら nil を返す
  # 2. 通常形式（youtube.com/watch?v=）の場合:
  #    - URLをパースしてクエリ文字列（?v=xxx）を取得
  #    - v= で始まるパラメータを見つけて値を取得
  # 3. 短縮URL形式（youtu.be/）の場合:
  #    - youtu.be/ 以降の文字列を取得
  #
  # 【&. とは？】（ぼっち演算子）
  # 左側がnilの場合、エラーにならずにnilを返す。
  # 例: nil&.split("&") は nil を返す
  #
  def self.extract_video_id(url)
    return nil unless url.present?

    if url.include?("youtube.com/watch")
      # 通常形式: https://www.youtube.com/watch?v=動画ID&list=プレイリストID
      # URI.parse(url).query で "v=xxx&list=yyy" 部分を取得
      # split("&") で ["v=xxx", "list=yyy"] に分割
      # find { |p| p.start_with?("v=") } で "v=xxx" を見つける
      # delete_prefix("v=") で "xxx" を取得
      URI.parse(url).query&.split("&")
         &.find { |p| p.start_with?("v=") }
         &.delete_prefix("v=")
    elsif url.include?("youtu.be/")
      # 短縮形式: https://youtu.be/動画ID?t=10
      # split("youtu.be/") で ["https://", "動画ID?t=10"] に分割
      # .last で "動画ID?t=10" を取得
      # split("?").first で "動画ID" を取得
      url.split("youtu.be/").last&.split("?")&.first
    end
  rescue URI::InvalidURIError
    # 無効なURLの場合はnilを返す
    nil
  end

  # ------------------------------------------
  # 動画IDでPostを検索または作成
  # ------------------------------------------
  # 【何をするメソッド？】
  # 同じ動画IDのPostが既にあれば返し、なければ新規作成する。
  #
  # 【なぜこのメソッドが必要か？】
  # 同じ動画が複数登録されるのを防ぐため。
  # 異なるURLでも同じ動画なら1つのPostにまとめる。
  # 例: youtube.com/watch?v=xxx と youtu.be/xxx は同じ動画
  #
  # 【find_or_create_by とは？】
  # 指定条件で検索し、見つからなければ作成するメソッド。
  # ブロック { |post| ... } は新規作成時のみ実行される。
  #
  def self.find_or_create_by_video(youtube_url:)
    video_id = extract_video_id(youtube_url)
    return nil unless video_id

    find_or_create_by(youtube_video_id: video_id) do |post|
      post.youtube_url = youtube_url
    end
  end

  # ------------------------------------------
  # YouTubeサムネイルURLを取得
  # ------------------------------------------
  # 【何をするメソッド？】
  # YouTube動画のサムネイル画像URLを生成する。
  #
  # 【サイズオプション】
  # - :default (120x90) - 小さい
  # - :mqdefault (320x180) - 中サイズ（デフォルト）
  # - :hqdefault (480x360) - 大きい
  # - :maxresdefault (1280x720) - 最大（存在しない場合あり）
  #
  # 【YouTubeのサムネイルURL規則】
  # https://img.youtube.com/vi/動画ID/サイズ.jpg
  #
  def youtube_thumbnail_url(size: :mqdefault)
    return nil unless youtube_video_id

    "https://img.youtube.com/vi/#{youtube_video_id}/#{size}.jpg"
  end

  # ------------------------------------------
  # YouTube埋め込みURLを取得
  # ------------------------------------------
  # 【何をするメソッド？】
  # iframeで動画を埋め込む際に使うURLを生成する。
  #
  # 【使用例（ビュー側）】
  # <iframe src="<%= @post.youtube_embed_url %>" ...></iframe>
  #
  def youtube_embed_url
    return nil unless youtube_video_id

    "https://www.youtube.com/embed/#{youtube_video_id}"
  end

  # ==========================================
  # エントリー関連メソッド
  # ==========================================

  # ------------------------------------------
  # 特定ユーザーのエントリーを取得
  # ------------------------------------------
  # 【何をするメソッド？】
  # この動画に対して、指定ユーザーが作成した
  # アクションプランの一覧を返す。
  #
  def entries_by_user(user)
    post_entries.where(user: user)
  end

  # ------------------------------------------
  # 特定ユーザーがエントリーを持っているか
  # ------------------------------------------
  # 【何をするメソッド？】
  # 指定ユーザーがこの動画にアクションプランを
  # 作成済みかどうかをチェックする。
  #
  # 【exists? とは？】
  # レコードが存在するかをBooleanで返す。
  # countやpresentより効率的（全件取得しない）。
  #
  def has_entries_by?(user)
    post_entries.exists?(user: user)
  end

  # ==========================================
  # ランキング関連メソッド
  # ==========================================

  # ------------------------------------------
  # この動画のアクション数ランキング順位を取得
  # ------------------------------------------
  # 【何をするメソッド？】
  # この動画がアクション数で何位かを返す。
  # TOP10以内ならその順位、それ以外はnilを返す。
  #
  # 【処理の流れ】
  # 1. この動画のアクション数をカウント
  # 2. この動画より多いアクション数を持つ動画の数を数える
  # 3. その数 + 1 が順位
  #
  # 例: 10件のアクションがあり、それより多い動画が2つなら3位
  #
  def action_count_rank
    my_count = post_entries.count
    return nil if my_count == 0

    # 自分より多いアクション数の動画を数える
    rank = Post.joins(:post_entries)
               .group("posts.id")
               .having("COUNT(post_entries.id) > ?", my_count)
               .count
               .size + 1

    # TOP10以内なら順位を返す、それ以外はnil
    rank <= 10 ? rank : nil
  end

  # ==========================================
  # セクション用クラスメソッド（一覧表示用）
  # ==========================================

  # ------------------------------------------
  # 人気のチャンネル一覧を取得
  # ------------------------------------------
  # 【何をするメソッド？】
  # アクション数の合計が多いチャンネル順に取得。
  # トップページのチャンネルランキングで使用。
  #
  # 【戻り値の形式】
  # [
  #   {
  #     channel_name: "チャンネル名",
  #     channel_id: "UCxxxx",
  #     thumbnail_url: "https://...",
  #     post_count: 5,      # 登録動画数
  #     action_count: 100,  # 総アクション数
  #     youtube_url: "https://www.youtube.com/channel/..."
  #   },
  #   ...
  # ]
  #
  # 【SQLの解説（簡略化）】
  # SELECT チャンネル名, 動画数, アクション数
  # FROM posts JOIN post_entries
  # WHERE チャンネル名がある
  # GROUP BY チャンネル名
  # ORDER BY アクション数 DESC
  # LIMIT 20
  #
  # 【array_agg とは？】
  # PostgreSQLの関数。グループ内の値を配列にする。
  # [1] で最初の要素を取得（どれか1つ取れればOK）。
  #
  def self.popular_channels(limit: 20)
    Post
      .where.not(youtube_channel_name: [ nil, "" ])  # チャンネル名があるもののみ
      .joins(:post_entries)                          # アクションプランと結合
      .group(:youtube_channel_name)                  # チャンネルごとにグループ化
      .having("COUNT(DISTINCT posts.id) >= 1")       # 動画が1つ以上
      .order("COUNT(post_entries.id) DESC")          # アクション数が多い順
      .limit(limit)
      .pluck(
        :youtube_channel_name,
        Arel.sql("(array_agg(youtube_channel_id))[1]"),
        Arel.sql("(array_agg(youtube_channel_thumbnail_url))[1]"),
        Arel.sql("COUNT(DISTINCT posts.id)"),        # 動画数
        Arel.sql("COUNT(post_entries.id)")           # アクション数
      )
      .map do |name, channel_id, thumbnail, post_count, action_count|
        # pluckの結果を扱いやすいHashに変換
        {
          channel_name: name,
          channel_id: channel_id,
          thumbnail_url: thumbnail,
          post_count: post_count,
          action_count: action_count,
          youtube_url: build_channel_url(channel_id, name)
        }
      end
  end

  # ------------------------------------------
  # アクション数順で動画を取得
  # ------------------------------------------
  # 【何をするメソッド？】
  # アクションプランが多い順に動画を取得する。
  # トップページの人気動画ランキングで使用。
  #
  # 【引数】
  # - limit: 取得件数（nilで無制限）
  #
  def self.by_action_count(limit: 20)
    base = Post
      .joins(:post_entries)                             # post_entriesと結合
      .group("posts.id")                                # 動画ごとにグループ化
      .order(Arel.sql("COUNT(post_entries.id) DESC"))   # アクション数が多い順
      .select("posts.*")                                # 全カラムを取得

    limit ? base.limit(limit) : base
  end

  private

  # ==========================================
  # プライベートメソッド（外部から呼べない）
  # ==========================================

  # ------------------------------------------
  # YouTube情報を取得すべきか判定
  # ------------------------------------------
  # 【何をするメソッド？】
  # before_save コールバックの実行条件を判定。
  #
  # 【いつtrueになるか？】
  # - 新規作成時（new_record?）
  # - URLが変更された時（youtube_url_changed?）
  #
  # 【_changed? とは？】
  # ActiveRecordが自動生成するメソッド。
  # その属性が変更されたかどうかを返す。
  #
  def should_fetch_youtube_info?
    return false if youtube_url.blank?

    new_record? || youtube_url_changed?
  end

  # ------------------------------------------
  # YouTube動画IDをセット
  # ------------------------------------------
  # URLから動画IDを抽出してカラムに保存する。
  # before_save で自動実行される。
  #
  def set_youtube_video_id
    self.youtube_video_id = self.class.extract_video_id(youtube_url)
  end

  # ------------------------------------------
  # YouTube APIから動画情報を取得
  # ------------------------------------------
  # 【何をするメソッド？】
  # YoutubeServiceを使ってAPIから動画情報を取得し、
  # 各カラムにセットする。
  # before_save で自動実行される。
  #
  # 【取得する情報】
  # - タイトル
  # - チャンネル名
  # - チャンネルID
  # - チャンネルのサムネイル画像URL
  #
  def fetch_youtube_info
    info = YoutubeService.fetch_video_info(youtube_url)
    return if info.nil?

    self.youtube_title = info[:title]
    self.youtube_channel_name = info[:channel_name]
    self.youtube_channel_id = info[:channel_id]
    self.youtube_channel_thumbnail_url = info[:channel_thumbnail_url]
  end

  # ------------------------------------------
  # チャンネルURLを生成
  # ------------------------------------------
  # 【何をするメソッド？】
  # チャンネルページへのURLを生成する。
  #
  # 【処理の流れ】
  # 1. channel_idがあれば、直接リンク（/channel/UCxxx）
  # 2. なければ、検索結果ページへのリンク
  #
  # 【ERB::Util.url_encode とは？】
  # URLに使えない文字（日本語など）をエンコードする。
  # 例: "日本語" → "%E6%97%A5%E6%9C%AC%E8%AA%9E"
  #
  def self.build_channel_url(channel_id, channel_name)
    if channel_id.present?
      "https://www.youtube.com/channel/#{channel_id}"
    else
      "https://www.youtube.com/results?search_query=#{ERB::Util.url_encode(channel_name)}"
    end
  end
end
