# YouTube動画モデル
# ユーザーが登録した動画を管理し、複数のアクションプラン(PostEntry)と紐づく

class Post < ApplicationRecord
  belongs_to :user, optional: true                                                              # 投稿者（任意）
  has_many :post_entries, dependent: :destroy                                                   # アクションプラン一覧

  validates :youtube_url, presence: true                                                        # URL必須
  validates :youtube_url, format: {                                                             # URL形式チェック
    with: %r{\A(https?://)?(www\.)?(youtube\.com/watch\?v=|youtu\.be/)[\w-]+(\?.*)?(?:#.*)?\z}, # YouTube URLの正規表現
    message: "は有効なYouTube URLを入力してください"                                              # エラーメッセージ
  }
  validates :action_plan, length: { maximum: 100 }, allow_blank: true                           # 旧形式（互換性のため残存）

  before_save :set_youtube_video_id, if: :should_fetch_youtube_info?                            # 動画IDをセット
  before_save :fetch_youtube_info, if: :should_fetch_youtube_info?                              # YouTube APIから情報取得

  scope :recent, -> { order(created_at: :desc) }                                                # 新しい順
  scope :with_entries, -> { joins(:post_entries).distinct }                                     # エントリーありのみ
  scope :with_achieved_entries, -> {                                                            # 達成済みエントリーありのみ
    joins(:post_entries)                                                                        # エントリーと結合
      .where.not(post_entries: { achieved_at: nil })                                            # 達成済みのみ
      .distinct                                                                                 # 重複除去
  }

  # Ransack検索で許可するカラム
  def self.ransackable_attributes(_auth_object = nil)
    %w[action_plan youtube_title youtube_channel_name created_at]                               # 検索可能カラム
  end

  # Ransack検索で許可する関連
  def self.ransackable_associations(_auth_object = nil)
    %w[user]                                                                                    # user経由の検索を許可
  end

  # DBの値またはURLから動画IDを取得
  def youtube_video_id
    read_attribute(:youtube_video_id) || self.class.extract_video_id(youtube_url)               # read_attribute使用: selfだと無限ループ
  end

  # URLから動画IDを抽出
  def self.extract_video_id(url)
    return nil unless url.present?                                                              # URLが空なら終了

    if url.include?("youtube.com/watch")                                                        # 通常形式の場合
      URI.parse(url).query&.split("&")&.find { |p| p.start_with?("v=") }&.delete_prefix("v=")   # クエリからv=を抽出
    elsif url.include?("youtu.be/")                                                             # 短縮URL形式の場合
      url.split("youtu.be/").last&.split("?")&.first                                            # youtu.be/以降を抽出
    end
  rescue URI::InvalidURIError                                                                   # 無効なURLの場合
    nil                                                                                         # nilを返す
  end

  # 動画IDで検索または新規作成
  def self.find_or_create_by_video(youtube_url:)
    video_id = extract_video_id(youtube_url)                                                    # URLから動画ID抽出
    return nil unless video_id                                                                  # IDがなければ終了

    find_or_create_by(youtube_video_id: video_id) { |post| post.youtube_url = youtube_url }     # 同じ動画は1つにまとめる
  end

  # サムネイルURLを生成（サイズ: default/mqdefault/hqdefault/maxresdefault）
  def youtube_thumbnail_url(size: :mqdefault)
    return nil unless youtube_video_id                                                          # 動画IDがなければ終了
    "https://img.youtube.com/vi/#{youtube_video_id}/#{size}.jpg"                                # YouTubeサムネイルURL
  end

  # 埋め込み用URLを生成
  def youtube_embed_url
    return nil unless youtube_video_id                                                          # 動画IDがなければ終了
    "https://www.youtube.com/embed/#{youtube_video_id}"                                         # 埋め込みURL
  end

  # 指定ユーザーのエントリー一覧を取得
  def entries_by_user(user)
    post_entries.where(user: user)                                                              # ユーザーで絞り込み
  end

  # 指定ユーザーがエントリーを持っているか
  def has_entries_by?(user)
    post_entries.exists?(user: user)                                                            # 存在チェック
  end

  # アクション数でのランキング順位を取得（TOP10以内ならその順位、それ以外はnil）
  def action_count_rank
    my_count = post_entries.count                                                               # 自分のアクション数
    return nil if my_count == 0                                                                 # 0なら終了

    rank = Post.joins(:post_entries)                                                            # エントリーと結合
               .group("posts.id")                                                               # 動画ごとにグループ化
               .having("COUNT(post_entries.id) > ?", my_count)                                  # 自分より多いもののみ
               .count                                                                           # 件数取得
               .size + 1                                                                        # +1が自分の順位

    rank <= 10 ? rank : nil                                                                     # TOP10以内なら順位を返す
  end

  # 人気チャンネル一覧を取得（アクション数順）
  def self.popular_channels(limit: 20)
    Post
      .where.not(youtube_channel_name: [ nil, "" ])                                             # チャンネル名があるもののみ
      .joins(:post_entries)                                                                     # エントリーと結合
      .where.not(post_entries: { achieved_at: nil })                                            # 達成済みのみ
      .group(:youtube_channel_name)                                                             # チャンネルごとにグループ化
      .having("COUNT(DISTINCT posts.id) >= 1")                                                  # 動画が1つ以上
      .order("COUNT(post_entries.id) DESC")                                                     # アクション数が多い順
      .limit(limit)                                                                             # 件数制限
      .pluck(
        :youtube_channel_name,                                                                  # チャンネル名
        Arel.sql("(array_agg(youtube_channel_id))[1]"),                                         # チャンネルID（1つ取得）
        Arel.sql("(array_agg(youtube_channel_thumbnail_url))[1]"),                              # サムネイルURL（1つ取得）
        Arel.sql("COUNT(DISTINCT posts.id)"),                                                   # 動画数
        Arel.sql("COUNT(post_entries.id)")                                                      # アクション数
      )
      .map do |name, channel_id, thumbnail, post_count, action_count|                           # 結果をHashに変換
        {
          channel_name: name,                                                                   # チャンネル名
          channel_id: channel_id,                                                               # チャンネルID
          thumbnail_url: thumbnail,                                                             # サムネイルURL
          post_count: post_count,                                                               # 動画数
          action_count: action_count,                                                           # アクション数
          youtube_url: build_channel_url(channel_id, name)                                      # チャンネルURL
        }
      end
  end

  # アクション数順で動画を取得
  def self.by_action_count(limit: 20)
    base = Post
      .joins(:post_entries)                                                                     # エントリーと結合
      .where.not(post_entries: { achieved_at: nil })                                            # 達成済みのみ
      .group("posts.id")                                                                        # 動画ごとにグループ化
      .order(Arel.sql("COUNT(post_entries.id) DESC"))                                           # アクション数が多い順
      .select("posts.*")                                                                        # 全カラムを取得

    limit ? base.limit(limit) : base                                                            # 件数制限（nilなら無制限）
  end

  private

  # YouTube情報を取得すべきか判定（新規作成時またはURL変更時）
  def should_fetch_youtube_info?
    return false if youtube_url.blank?                                                          # URLが空なら取得しない
    new_record? || youtube_url_changed?                                                         # 新規作成またはURL変更時
  end

  # URLから動画IDを抽出してセット
  def set_youtube_video_id
    self.youtube_video_id = self.class.extract_video_id(youtube_url)                            # 動画IDをセット
  end

  # YouTube APIから動画情報を取得してセット
  def fetch_youtube_info
    info = YoutubeService.fetch_video_info(youtube_url)                                         # APIから情報取得
    return if info.nil?                                                                         # 取得失敗なら終了

    self.youtube_title = info[:title]                                                           # タイトルをセット
    self.youtube_channel_name = info[:channel_name]                                             # チャンネル名をセット
    self.youtube_channel_id = info[:channel_id]                                                 # チャンネルIDをセット
    self.youtube_channel_thumbnail_url = info[:channel_thumbnail_url]                           # チャンネルサムネイルをセット
  end

  # チャンネルURLを生成
  def self.build_channel_url(channel_id, channel_name)
    if channel_id.present?                                                                      # チャンネルIDがある場合
      "https://www.youtube.com/channel/#{channel_id}"                                           # 直接リンク
    else                                                                                        # チャンネルIDがない場合
      "https://www.youtube.com/results?search_query=#{ERB::Util.url_encode(channel_name)}"      # 検索結果へリンク
    end
  end
end
