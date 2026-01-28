# アクションプランモデル（ユーザーの行動宣言）
# YouTube動画を見て「○○をやる！」と宣言した内容を管理

class PostEntry < ApplicationRecord
  belongs_to :post                                                                    # 元になった動画
  belongs_to :user                                                                    # 作成者
  has_many :entry_likes, dependent: :destroy                                          # もらったいいね一覧

  before_validation :set_auto_deadline, on: :create                                   # 新規作成時に期限自動設定
  after_destroy :cleanup_empty_post                                                   # 削除後に空のPostをクリーンアップ
  before_update :track_old_post                                                       # 更新前の元Postを記録
  after_update :cleanup_old_post                                                      # 更新後に元Postをクリーンアップ

  validates :content, presence: true                                                  # プラン内容は必須
  validates :reflection, length: { maximum: 500 }, allow_blank: true                  # 振り返りは500文字まで

  scope :recent, -> { order(created_at: :desc) }                                      # 新しい順
  scope :not_achieved, -> { where(achieved_at: nil) }                                 # 未達成のみ
  scope :achieved, -> { where.not(achieved_at: nil) }                                 # 達成済みのみ
  scope :expired, -> { not_achieved.where("deadline < ?", Date.current) }             # 期限切れのみ

  # 達成済みか判定
  def achieved?
    achieved_at.present?                                                              # achieved_atがあれば達成済み
  end

  # 達成状態をトグル（切り替え）
  def achieve!
    if achieved?                                                                      # 達成済みの場合
      update!(achieved_at: nil)                                                       # 未達成に戻す
    else                                                                              # 未達成の場合
      update!(achieved_at: Time.current)                                              # 達成済みにする
    end
  end

  # 残り日数を計算
  def days_remaining
    return nil if achieved?                                                           # 達成済みならnil
    return nil if deadline.blank?                                                     # 期限がなければnil
    (deadline - Date.current).to_i                                                    # 残り日数を整数で返す
  end

  # 期限のステータスを取得（UI表示用）
  def deadline_status
    days = days_remaining                                                             # 残り日数を取得
    return :achieved if achieved?                                                     # 達成済み
    return :expired if days.nil? || days < 0                                          # 期限切れ

    case days                                                                         # 残り日数で分岐
    when 0 then :today                                                                # 今日が期限
    when 1 then :urgent                                                               # 明日が期限
    when 2..3 then :warning                                                           # 2-3日以内
    else :normal                                                                      # 4日以上先
    end
  end

  # 指定ユーザーがいいね済みか判定
  def liked_by?(user)
    return false if user.nil?                                                         # ログインしていなければfalse
    entry_likes.exists?(user_id: user.id)                                             # いいねが存在するか確認
  end

  # カスタムサムネイルの署名付きURLを取得
  def signed_thumbnail_url
    generate_signed_url(thumbnail_url)                                                # S3署名付きURLを生成
  end

  # 達成記録画像の署名付きURLを取得
  def signed_result_image_url
    generate_signed_url(result_image)                                                 # S3署名付きURLを生成
  end

  # 達成記録表示用サムネイルURL（優先順位: 達成画像 > カスタム > YouTube）
  def display_result_thumbnail_url
    signed_result_image_url ||                                                        # 達成記録画像があれば最優先
      signed_thumbnail_url ||                                                         # なければカスタムサムネイル
      "https://i.ytimg.com/vi/#{post.youtube_video_id}/mqdefault.jpg"                 # なければYouTubeサムネイル
  end

  # 感想・画像付きで達成記録
  def achieve_with_reflection!(reflection_text: nil, result_image_s3_key: nil)
    transaction do                                                                    # トランザクション開始
      self.reflection = reflection_text if reflection_text.present?                   # 振り返りコメントをセット
      self.result_image = result_image_s3_key if result_image_s3_key.present?         # 達成画像のS3キーをセット
      self.achieved_at = Time.current                                                 # 達成日時をセット
      save!                                                                           # 保存
    end
  end

  # 感想・画像の編集
  def update_reflection!(reflection_text:, result_image_s3_key: nil)
    attrs = { reflection: reflection_text }                                           # 更新属性を準備
    attrs[:result_image] = result_image_s3_key if result_image_s3_key.present?        # 画像があれば追加
    update!(attrs)                                                                    # 更新実行
  end

  private

  # S3署名付きURLを生成（共通処理）
  def generate_signed_url(url_or_key, expires_in: 600)
    return nil if url_or_key.blank?                                                   # 空ならnilを返す

    s3_key = extract_s3_key(url_or_key)                                               # URLからS3キーを抽出
    return nil if s3_key.blank?                                                       # キーがなければnil

    s3 = Aws::S3::Resource.new(                                                       # AWS S3クライアントを作成
      region: ENV["AWS_REGION"],                                                      # リージョン設定
      access_key_id: ENV["AWS_ACCESS_KEY_ID"],                                        # アクセスキー
      secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"]                                 # シークレットキー
    )

    s3.bucket(ENV["AWS_BUCKET"]).object(s3_key).presigned_url(:get, expires_in: expires_in)  # 署名付きURL生成
  rescue Aws::S3::Errors::ServiceError                                                # S3エラーの場合
    nil                                                                               # nilを返す
  end

  # S3キーを抽出（URLまたはキーから）
  def extract_s3_key(url)
    return url unless url.start_with?("http://", "https://")                          # URLでなければそのまま返す
    URI.parse(url).path[1..]                                                          # URLからパス部分を抽出
  rescue URI::InvalidURIError                                                         # 無効なURLの場合
    nil                                                                               # nilを返す
  end

  # 期限を自動設定（新規作成時、未指定なら7日後）
  def set_auto_deadline
    self.deadline ||= Date.current + 7.days                                           # 期限がなければ7日後をセット
  end

  # 空のPostを自動削除
  def cleanup_empty_post
    return if post.blank?                                                             # Postがなければ終了
    post.destroy if post.post_entries.count == 0                                      # エントリーがなければPost削除
  end

  # 更新前の元Postを記録
  def track_old_post
    @old_post_id = post_id_was if post_id_changed?                                    # post_id変更時に元IDを記録
  end

  # 元Postをクリーンアップ
  def cleanup_old_post
    return unless @old_post_id                                                        # 元IDがなければ終了

    old_post = Post.find_by(id: @old_post_id)                                         # 元Postを検索
    old_post.destroy if old_post && old_post.post_entries.count == 0                  # エントリーがなければ削除
    @old_post_id = nil                                                                # 記録をクリア
  end
end
