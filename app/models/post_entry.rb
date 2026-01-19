# app/models/post_entry.rb
# アクションプラン専用モデル
class PostEntry < ApplicationRecord
  belongs_to :post
  belongs_to :user
  has_many :entry_flames, dependent: :destroy

  # コールバック
  before_validation :set_auto_deadline, on: :create

  # バリデーション
  validates :content, presence: true
  validates :reflection, length: { maximum: 500 }, allow_blank: true
  # 同じ動画への複数投稿を許可（未達成がなければOK）
  validate :one_incomplete_action_per_user, on: :create

  # スコープ
  scope :recent, -> { order(created_at: :desc) }
  scope :not_achieved, -> { where(achieved_at: nil) }
  scope :achieved, -> { where.not(achieved_at: nil) }
  scope :expired, -> { not_achieved.where("deadline < ?", Date.current) }

  # 達成済みか
  def achieved?
    achieved_at.present?
  end

  # 達成をトグル
  def achieve!
    if achieved?
      # 達成を取り消す場合
      update!(achieved_at: nil)
    else
      # 達成する場合
      update!(achieved_at: Time.current)
      # サムネイル生成ジョブを起動（バックグラウンドで実行）
      ThumbnailGenerationJob.perform_later(id)
    end
  end

  # 残り日数を計算（達成済みはnil）
  def days_remaining
    return nil if achieved?
    return nil if deadline.blank?

    (deadline - Date.current).to_i
  end

  # 残り日数の表示用ステータス
  def deadline_status
    days = days_remaining
    return :achieved if achieved?
    return :expired if days.nil? || days < 0

    case days
    when 0 then :today
    when 1 then :urgent
    when 2..3 then :warning
    else :normal
    end
  end

  # 匿名表示かどうか
  def display_anonymous?
    anonymous?
  end

  # 表示用ユーザー名（匿名なら「匿名」を返す）
  def display_user_name
    anonymous? ? "匿名" : user&.name
  end

  # 表示用アバター（匿名ならnilを返す）
  def display_avatar
    anonymous? ? nil : user&.avatar
  end

  # 炎マーク済みかどうか
  def flamed_by?(user)
    return false if user.nil?
    entry_flames.exists?(user_id: user.id)
  end

  # サムネイルURLを取得（署名付きURL）
  # カスタム画像がある場合: S3署名付きURLを返す
  # ない場合: nil（YouTubeサムネイルを使用）
  def signed_thumbnail_url
    return nil if thumbnail_url.blank?

    # S3キーを取得（フルURLの場合はキーを抽出）
    s3_key = extract_s3_key(thumbnail_url)
    return nil if s3_key.blank?

    # 署名付きURLを生成
    s3 = Aws::S3::Resource.new(
      region: ENV["AWS_REGION"],
      access_key_id: ENV["AWS_ACCESS_KEY_ID"],
      secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"]
    )
    obj = s3.bucket(ENV["AWS_BUCKET"]).object(s3_key)
    obj.presigned_url(:get, expires_in: 600)
  rescue Aws::S3::Errors::ServiceError
    nil
  end

  # S3キーを抽出（フルURLの場合も対応）
  def extract_s3_key(url)
    return url unless url.start_with?("http://", "https://")

    # S3 URLからキーを抽出
    # 例: https://bucket.s3.region.amazonaws.com/path/to/file.png -> path/to/file.png
    uri = URI.parse(url)
    uri.path[1..] # 先頭の "/" を除去
  rescue URI::InvalidURIError
    nil
  end

  # 達成記録画像の署名付きURLを取得
  def signed_result_image_url
    return nil if result_image.blank?

    s3_key = extract_s3_key(result_image)
    return nil if s3_key.blank?

    s3 = Aws::S3::Resource.new(
      region: ENV["AWS_REGION"],
      access_key_id: ENV["AWS_ACCESS_KEY_ID"],
      secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"]
    )
    obj = s3.bucket(ENV["AWS_BUCKET"]).object(s3_key)
    obj.presigned_url(:get, expires_in: 600)
  rescue Aws::S3::Errors::ServiceError
    nil
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

      # 既存のサムネイル生成ジョブは維持
      ThumbnailGenerationJob.perform_later(id)
    end
  end

  # 感想の編集
  def update_reflection!(reflection_text:)
    update!(reflection: reflection_text)
  end

  private

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
