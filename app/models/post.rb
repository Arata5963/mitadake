# app/models/post.rb
class Post < ApplicationRecord
  belongs_to :user, optional: true
  has_many :achievements, dependent: :destroy
  has_many :cheers, dependent: :destroy
  has_many :post_entries, dependent: :destroy
  has_many :youtube_comments, dependent: :destroy

  scope :recent, -> { order(created_at: :desc) }
  scope :without_entries, -> {
    left_joins(:post_entries)
      .group("posts.id")
      .having("COUNT(post_entries.id) = 0")
  }
  scope :stale_empty, -> {
    without_entries.where("posts.created_at < ?", 24.hours.ago)
  }

  before_save :set_youtube_video_id, if: :should_fetch_youtube_info?
  before_save :fetch_youtube_info, if: :should_fetch_youtube_info?

  # action_planはPostEntry経由で管理するが、互換性のため残す
  validates :action_plan, length: { maximum: 100 }, allow_blank: true

  # YouTube URL検証（必須）
  validates :youtube_url, presence: true
  validates :youtube_url, format: {
    with: %r{\A(https?://)?(www\.)?(youtube\.com/watch\?v=|youtu\.be/)[\w-]+(\?.*)?(?:#.*)?\z},
    message: "は有効なYouTube URLを入力してください"
  }

  def self.ransackable_attributes(_auth_object = nil)
    %w[action_plan youtube_title youtube_channel_name created_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[user achievements]
  end

  def cheered_by?(user)
    cheers.exists?(user_id: user.id)
  end

  # エントリー関連ヘルパー
  def latest_entry
    post_entries.recent.first
  end

  def entries_count
    post_entries.count
  end

  def has_action_entries?
    post_entries.where(entry_type: :action).exists?
  end

  # YouTube動画ID取得（保存値優先、なければURLから抽出）
  def youtube_video_id
    read_attribute(:youtube_video_id) || self.class.extract_video_id(youtube_url)
  end

  # クラスメソッド：URLから動画IDを抽出
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

  # 動画IDでPostを検索または作成（ユーザー不問）
  def self.find_or_create_by_video(youtube_url:)
    video_id = extract_video_id(youtube_url)
    return nil unless video_id

    find_or_create_by(youtube_video_id: video_id) do |post|
      post.youtube_url = youtube_url
    end
  end

  # 動画IDでPostを検索または初期化（互換性のため残す）
  def self.find_or_initialize_by_video(youtube_url:)
    video_id = extract_video_id(youtube_url)
    return nil unless video_id

    post = find_or_initialize_by(youtube_video_id: video_id)
    post.youtube_url = youtube_url if post.new_record?
    post
  end

  # YouTubeサムネイルURL取得
  def youtube_thumbnail_url(size: :mqdefault)
    return nil unless youtube_video_id

    "https://img.youtube.com/vi/#{youtube_video_id}/#{size}.jpg"
  end

  # YouTube埋め込みURL取得
  def youtube_embed_url
    return nil unless youtube_video_id

    "https://www.youtube.com/embed/#{youtube_video_id}"
  end

  # エントリーを持つユーザー一覧
  def entry_users
    User.where(id: post_entries.select(:user_id).distinct)
  end

  # 特定ユーザーのエントリーを取得
  def entries_by_user(user)
    post_entries.where(user: user)
  end

  # 特定ユーザーがエントリーを持っているか
  def has_entries_by?(user)
    post_entries.exists?(user: user)
  end

  # 達成率データを返す（グラフ表示用）
  def achievement_stats
    total = post_entries.count
    return nil if total == 0

    achieved = post_entries.achieved.count
    percentage = (achieved.to_f / total * 100).round

    { total: total, achieved: achieved, percentage: percentage }
  end

  # アクション数ランキング（TOP 10内なら順位を返す、それ以外はnil）
  def action_count_rank
    my_count = post_entries.count
    return nil if my_count == 0

    # 自分より多いアクション数を持つ投稿の数 + 1 = 順位
    rank = Post.joins(:post_entries)
               .group("posts.id")
               .having("COUNT(post_entries.id) > ?", my_count)
               .count
               .size + 1

    rank <= 10 ? rank : nil
  end

  # YouTubeチャンネルURL（外部リンク用）
  def youtube_channel_url
    return nil unless youtube_channel_id.present?

    "https://www.youtube.com/channel/#{youtube_channel_id}"
  end

  # ===== セクション用クラスメソッド =====

  # 人気のチャンネル（総アクション数順、2投稿以上）
  # @return [Array<Hash>] [{ channel_name:, channel_id:, thumbnail_url:, post_count:, action_count:, youtube_url: }, ...]
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
        youtube_url = if channel_id.present?
          "https://www.youtube.com/channel/#{channel_id}"
        else
          "https://www.youtube.com/results?search_query=#{ERB::Util.url_encode(name)}"
        end

        {
          channel_name: name,
          channel_id: channel_id,
          thumbnail_url: thumbnail,
          post_count: post_count,
          action_count: action_count,
          youtube_url: youtube_url
        }
      end
  end

  # 急上昇（過去30日のアクション数が多い投稿）
  # @param limit [Integer, nil] 取得数（nilでページネーション用）
  def self.trending(limit: 20)
    base = Post
      .joins(:post_entries)
      .where("post_entries.created_at >= ?", 30.days.ago)
      .group("posts.id")
      .order(Arel.sql("COUNT(post_entries.id) DESC"))
      .select("posts.*")

    limit ? base.limit(limit) : base
  end

  # アクション数ランキング（総アクション数順）
  # @param limit [Integer, nil] 取得数（nilでページネーション用）
  def self.by_action_count(limit: 20)
    base = Post
      .joins(:post_entries)
      .group("posts.id")
      .order(Arel.sql("COUNT(post_entries.id) DESC"))
      .select("posts.*")

    limit ? base.limit(limit) : base
  end

  private

  # YouTube情報を取得すべきかどうか判定
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
end
