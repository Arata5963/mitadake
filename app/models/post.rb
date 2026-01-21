# app/models/post.rb
# YouTube動画を表すモデル
# 1つの動画に対して複数のユーザーがアクションプラン（PostEntry）を作成できる
class Post < ApplicationRecord
  # ===== アソシエーション =====
  belongs_to :user, optional: true
  has_many :post_entries, dependent: :destroy

  # ===== バリデーション =====
  validates :youtube_url, presence: true
  validates :youtube_url, format: {
    with: %r{\A(https?://)?(www\.)?(youtube\.com/watch\?v=|youtu\.be/)[\w-]+(\?.*)?(?:#.*)?\z},
    message: "は有効なYouTube URLを入力してください"
  }
  # 互換性のため残存（現在はPostEntry経由で管理）
  validates :action_plan, length: { maximum: 100 }, allow_blank: true

  # ===== コールバック =====
  before_save :set_youtube_video_id, if: :should_fetch_youtube_info?
  before_save :fetch_youtube_info, if: :should_fetch_youtube_info?

  # ===== スコープ =====
  scope :recent, -> { order(created_at: :desc) }
  scope :with_entries, -> { joins(:post_entries).distinct }

  # ===== Ransack設定 =====
  def self.ransackable_attributes(_auth_object = nil)
    %w[action_plan youtube_title youtube_channel_name created_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[user]
  end

  # ===== YouTube関連メソッド =====

  # YouTube動画IDを取得（保存値優先、なければURLから抽出）
  # @return [String, nil] 動画ID（例: "dQw4w9WgXcQ"）
  def youtube_video_id
    read_attribute(:youtube_video_id) || self.class.extract_video_id(youtube_url)
  end

  # URLから動画IDを抽出
  # @param url [String] YouTube URL
  # @return [String, nil] 動画ID
  # @example
  #   Post.extract_video_id("https://www.youtube.com/watch?v=dQw4w9WgXcQ") #=> "dQw4w9WgXcQ"
  #   Post.extract_video_id("https://youtu.be/dQw4w9WgXcQ") #=> "dQw4w9WgXcQ"
  def self.extract_video_id(url)
    return nil unless url.present?

    if url.include?("youtube.com/watch")
      URI.parse(url).query&.split("&")
         &.find { |p| p.start_with?("v=") }
         &.delete_prefix("v=")
    elsif url.include?("youtu.be/")
      url.split("youtu.be/").last&.split("?")&.first
    end
  rescue URI::InvalidURIError
    nil
  end

  # 動画IDでPostを検索または作成
  # @param youtube_url [String] YouTube URL
  # @return [Post, nil] 見つかったまたは作成されたPost
  def self.find_or_create_by_video(youtube_url:)
    video_id = extract_video_id(youtube_url)
    return nil unless video_id

    find_or_create_by(youtube_video_id: video_id) do |post|
      post.youtube_url = youtube_url
    end
  end

  # YouTubeサムネイルURLを取得
  # @param size [Symbol] サムネイルサイズ（:default, :mqdefault, :hqdefault, :maxresdefault）
  # @return [String, nil] サムネイルURL
  def youtube_thumbnail_url(size: :mqdefault)
    return nil unless youtube_video_id

    "https://img.youtube.com/vi/#{youtube_video_id}/#{size}.jpg"
  end

  # YouTube埋め込みURLを取得
  # @return [String, nil] 埋め込み用URL
  def youtube_embed_url
    return nil unless youtube_video_id

    "https://www.youtube.com/embed/#{youtube_video_id}"
  end

  # ===== エントリー関連メソッド =====

  # 特定ユーザーのエントリーを取得
  # @param user [User] ユーザー
  # @return [ActiveRecord::Relation<PostEntry>]
  def entries_by_user(user)
    post_entries.where(user: user)
  end

  # 特定ユーザーがエントリーを持っているか
  # @param user [User] ユーザー
  # @return [Boolean]
  def has_entries_by?(user)
    post_entries.exists?(user: user)
  end

  # ===== ランキング関連メソッド =====

  # この動画のアクション数ランキング順位を取得
  # @return [Integer, nil] TOP10内なら順位、それ以外はnil
  def action_count_rank
    my_count = post_entries.count
    return nil if my_count == 0

    rank = Post.joins(:post_entries)
               .group("posts.id")
               .having("COUNT(post_entries.id) > ?", my_count)
               .count
               .size + 1

    rank <= 10 ? rank : nil
  end

  # ===== セクション用クラスメソッド =====

  # 人気のチャンネル一覧を取得（総アクション数順）
  # @param limit [Integer] 取得件数
  # @return [Array<Hash>] チャンネル情報のハッシュ配列
  def self.popular_channels(limit: 20)
    Post
      .where.not(youtube_channel_name: [ nil, "" ])
      .joins(:post_entries)
      .group(:youtube_channel_name)
      .having("COUNT(DISTINCT posts.id) >= 1")
      .order("COUNT(post_entries.id) DESC")
      .limit(limit)
      .pluck(
        :youtube_channel_name,
        Arel.sql("(array_agg(youtube_channel_id))[1]"),
        Arel.sql("(array_agg(youtube_channel_thumbnail_url))[1]"),
        Arel.sql("COUNT(DISTINCT posts.id)"),
        Arel.sql("COUNT(post_entries.id)")
      )
      .map do |name, channel_id, thumbnail, post_count, action_count|
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

  # アクション数順で動画を取得
  # @param limit [Integer, nil] 取得件数（nilで無制限）
  # @return [ActiveRecord::Relation<Post>]
  def self.by_action_count(limit: 20)
    base = Post
      .joins(:post_entries)
      .group("posts.id")
      .order(Arel.sql("COUNT(post_entries.id) DESC"))
      .select("posts.*")

    limit ? base.limit(limit) : base
  end

  private

  # YouTube情報を取得すべきか判定
  def should_fetch_youtube_info?
    return false if youtube_url.blank?

    new_record? || youtube_url_changed?
  end

  # YouTube動画IDをセット
  def set_youtube_video_id
    self.youtube_video_id = self.class.extract_video_id(youtube_url)
  end

  # YouTube APIから動画情報を取得してセット
  def fetch_youtube_info
    info = YoutubeService.fetch_video_info(youtube_url)
    return if info.nil?

    self.youtube_title = info[:title]
    self.youtube_channel_name = info[:channel_name]
    self.youtube_channel_id = info[:channel_id]
    self.youtube_channel_thumbnail_url = info[:channel_thumbnail_url]
  end

  # チャンネルURLを生成
  # @param channel_id [String, nil] チャンネルID
  # @param channel_name [String] チャンネル名（フォールバック用）
  # @return [String] YouTubeチャンネルURL
  def self.build_channel_url(channel_id, channel_name)
    if channel_id.present?
      "https://www.youtube.com/channel/#{channel_id}"
    else
      "https://www.youtube.com/results?search_query=#{ERB::Util.url_encode(channel_name)}"
    end
  end
end
