# app/models/post_entry.rb
# アクションプラン（ユーザーが動画から学んで実行する行動計画）を表すモデル
#
# 主な機能:
# - YouTube動画（Post）に紐づいた行動計画を管理
# - 期限管理（デフォルト7日）
# - 達成状態の管理（achieved_at）
# - いいね機能（EntryLike経由）
# - S3に保存したサムネイル/達成記録画像の署名付きURL生成
#
# 制約:
# - 1ユーザーにつき未達成のアクションプランは1つのみ
class PostEntry < ApplicationRecord
  # ===== アソシエーション =====
  belongs_to :post      # 動画
  belongs_to :user      # 作成者
  has_many :entry_likes, dependent: :destroy  # いいね

  # ===== コールバック =====
  before_validation :set_auto_deadline, on: :create

  # ===== バリデーション =====
  validates :content, presence: true  # アクションプラン内容（必須）
  validates :reflection, length: { maximum: 500 }, allow_blank: true  # 振り返りコメント
  validate :one_incomplete_action_per_user, on: :create

  # ===== スコープ =====
  scope :recent, -> { order(created_at: :desc) }
  scope :not_achieved, -> { where(achieved_at: nil) }
  scope :achieved, -> { where.not(achieved_at: nil) }
  scope :expired, -> { not_achieved.where("deadline < ?", Date.current) }

  # ===== 達成状態メソッド =====

  # 達成済みか判定
  # @return [Boolean]
  def achieved?
    achieved_at.present?
  end

  # 達成状態をトグル（達成⇔未達成）
  # @return [Boolean] 保存成功したか
  def achieve!
    if achieved?
      update!(achieved_at: nil)
    else
      update!(achieved_at: Time.current)
    end
  end

  # ===== 期限関連メソッド =====

  # 残り日数を計算
  # @return [Integer, nil] 残り日数（達成済み/期限なしはnil）
  def days_remaining
    return nil if achieved?
    return nil if deadline.blank?

    (deadline - Date.current).to_i
  end

  # 期限のステータスを取得（UI表示用）
  # @return [Symbol] :achieved, :expired, :today, :urgent, :warning, :normal
  def deadline_status
    days = days_remaining
    return :achieved if achieved?
    return :expired if days.nil? || days < 0

    case days
    when 0 then :today      # 今日が期限
    when 1 then :urgent     # 明日が期限
    when 2..3 then :warning # 2-3日以内
    else :normal
    end
  end

  # ===== いいね関連メソッド =====

  # 指定ユーザーがいいね済みか判定
  # @param user [User, nil] ユーザー
  # @return [Boolean]
  def liked_by?(user)
    return false if user.nil?
    entry_likes.exists?(user_id: user.id)
  end

  # カスタムサムネイルの署名付きURLを取得
  # @return [String, nil] S3署名付きURL、またはnil（YouTubeサムネイルを使用）
  def signed_thumbnail_url
    generate_signed_url(thumbnail_url)
  end

  # 達成記録画像の署名付きURLを取得
  # @return [String, nil] S3署名付きURL
  def signed_result_image_url
    generate_signed_url(result_image)
  end

  # 達成記録表示用サムネイルURL（フォールバック付き）
  # 優先度: 達成記録画像 > 投稿時カスタムサムネイル > YouTubeサムネイル
  def display_result_thumbnail_url
    signed_result_image_url ||
      signed_thumbnail_url ||
      "https://i.ytimg.com/vi/#{post.youtube_video_id}/mqdefault.jpg"
  end

  # 感想・画像付きで達成
  # 署名付きURL方式: S3キーを直接受け取る
  def achieve_with_reflection!(reflection_text: nil, result_image_s3_key: nil)
    transaction do
      self.reflection = reflection_text if reflection_text.present?

      # S3キーを直接保存（Base64処理不要）
      if result_image_s3_key.present?
        self.result_image = result_image_s3_key
      end

      self.achieved_at = Time.current
      save!
    end
  end

  # 感想の編集
  def update_reflection!(reflection_text:)
    update!(reflection: reflection_text)
  end

  private

  # S3署名付きURLを生成（共通処理）
  # @param url_or_key [String, nil] S3キーまたはフルURL
  # @param expires_in [Integer] 有効期限（秒）
  # @return [String, nil] 署名付きURL
  def generate_signed_url(url_or_key, expires_in: 600)
    return nil if url_or_key.blank?

    s3_key = extract_s3_key(url_or_key)
    return nil if s3_key.blank?

    s3 = Aws::S3::Resource.new(
      region: ENV["AWS_REGION"],
      access_key_id: ENV["AWS_ACCESS_KEY_ID"],
      secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"]
    )
    s3.bucket(ENV["AWS_BUCKET"]).object(s3_key).presigned_url(:get, expires_in: expires_in)
  rescue Aws::S3::Errors::ServiceError
    nil
  end

  # S3キーを抽出（フルURLの場合も対応）
  # @param url [String] S3キーまたはフルURL
  # @return [String, nil] S3キー
  def extract_s3_key(url)
    return url unless url.start_with?("http://", "https://")

    # 例: https://bucket.s3.region.amazonaws.com/path/to/file.png -> path/to/file.png
    URI.parse(url).path[1..]
  rescue URI::InvalidURIError
    nil
  end

  # 期限を自動設定（作成日から7日後）
  def set_auto_deadline
    self.deadline ||= Date.current + 7.days
  end

  # ユーザー全体で未達成アクションは1つのみ
  def one_incomplete_action_per_user
    return if user.blank?

    existing = PostEntry.not_achieved.where(user: user).first
    if existing.present?
      errors.add(:base, "未達成のアクションプランがあります。達成してから新しいプランを投稿してください")
    end
  end

end
