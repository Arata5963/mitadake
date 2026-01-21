# app/models/post_entry.rb
# ==========================================
# アクションプラン（ユーザーの行動宣言）
# ==========================================
#
# 【このモデルの役割】
# ユーザーがYouTube動画を見て「○○をやる！」と宣言した内容を管理する。
# このアプリの最も重要なモデル。
#
# 【データベースのカラム（主要なもの）】
# - content: アクションプランの内容（「毎朝6時に起きる」など）
# - deadline: 期限日（デフォルトは作成日から7日後）
# - achieved_at: 達成日時（nilなら未達成、日時があれば達成済み）
# - reflection: 達成後の振り返りコメント
# - thumbnail_url: カスタムサムネイル画像のS3キー
# - result_image: 達成記録画像のS3キー
#
# 【他のモデルとの関係】
#
#   PostEntry（アクションプラン）
#     │
#     ├─ belongs_to :post（元になった動画）
#     │    └─ どの動画を見てこのプランを作ったか
#     │
#     ├─ belongs_to :user（作成者）
#     │    └─ 誰がこのプランを作ったか
#     │
#     └─ has_many :entry_likes（もらったいいね）
#          └─ 他のユーザーからの応援
#
# 【重要なルール】
# 1ユーザーにつき、未達成のアクションプランは1つまで。
# 達成してから次のプランを作成できる。
#
class PostEntry < ApplicationRecord

  # ==========================================
  # アソシエーション（他テーブルとの関連）
  # ==========================================
  #
  # 【belongs_to とは？】
  # 「このレコードは○○に属している」という関係。
  # post_entries テーブルには post_id と user_id が保存される。
  #

  # どの動画を見てこのプランを作ったか
  belongs_to :post

  # 誰がこのプランを作ったか
  belongs_to :user

  # 【has_many :entry_likes とは？】
  # このアクションプランについた「いいね」の一覧。
  # dependent: :destroy により、プランを削除すると
  # いいねも一緒に削除される。
  has_many :entry_likes, dependent: :destroy

  # ==========================================
  # コールバック（保存前後に自動実行される処理）
  # ==========================================
  #
  # 【before_validation とは？】
  # バリデーション（検証）が実行される前に呼ばれる。
  #
  # 【on: :create とは？】
  # 新規作成時のみ実行される（更新時は実行されない）。
  #
  # これにより、期限を指定しなくても自動で7日後がセットされる。
  #
  before_validation :set_auto_deadline, on: :create

  # ==========================================
  # バリデーション（データの検証ルール）
  # ==========================================

  # アクションプランの内容は必須
  validates :content, presence: true

  # 振り返りコメントは500文字まで（空でもOK）
  validates :reflection, length: { maximum: 500 }, allow_blank: true

  # 【カスタムバリデーション】
  # 1ユーザーにつき未達成のプランは1つまで
  # on: :create により新規作成時のみチェック
  validate :one_incomplete_action_per_user, on: :create

  # ==========================================
  # スコープ（よく使う検索条件をメソッド化）
  # ==========================================
  #
  # 【スコープとは？】
  # よく使う検索条件に名前をつけて再利用できるようにしたもの。
  #
  # 【-> { ... } とは？】
  # ラムダ（無名関数）。呼び出されるたびに実行される。
  # 「->」は「lambda」と同じ意味。
  #
  # 使用例:
  #   PostEntry.recent              # 新しい順
  #   PostEntry.not_achieved        # 未達成のみ
  #   PostEntry.achieved.recent     # 達成済みを新しい順に
  #

  # 新しい順に並べる
  scope :recent, -> { order(created_at: :desc) }

  # 未達成のプランのみ（achieved_at が nil）
  scope :not_achieved, -> { where(achieved_at: nil) }

  # 達成済みのプランのみ（achieved_at が入っている）
  scope :achieved, -> { where.not(achieved_at: nil) }

  # 期限切れのプランのみ（未達成かつ期限が過去）
  # Date.current は Rails が提供する「今日の日付」
  scope :expired, -> { not_achieved.where("deadline < ?", Date.current) }

  # ==========================================
  # 達成状態メソッド
  # ==========================================

  # ------------------------------------------
  # 達成済みか判定
  # ------------------------------------------
  # 【何をするメソッド？】
  # このアクションプランが達成済みかどうかを返す。
  #
  # 【.present? とは？】
  # nil でも空でもない場合に true を返す。
  # achieved_at に日時が入っていれば達成済み。
  #
  # 【? で終わるメソッド名】
  # Rubyの慣習で、true/false を返すメソッドは
  # 名前の最後に ? をつける。
  #
  def achieved?
    achieved_at.present?
  end

  # ------------------------------------------
  # 達成状態をトグル（切り替え）
  # ------------------------------------------
  # 【何をするメソッド？】
  # 達成済みなら未達成に、未達成なら達成済みに切り替える。
  #
  # 【! で終わるメソッド名】
  # Rubyの慣習で、「破壊的」な操作をするメソッドは
  # 名前の最後に ! をつける。
  # ここでは「データベースを更新する」という意味。
  #
  # 【update! とは？】
  # update と違い、保存に失敗すると例外が発生する。
  # 確実に保存したい場合に使う。
  #
  def achieve!
    if achieved?
      # 達成済み → 未達成に戻す
      update!(achieved_at: nil)
    else
      # 未達成 → 達成済みにする
      update!(achieved_at: Time.current)
    end
  end

  # ==========================================
  # 期限関連メソッド
  # ==========================================

  # ------------------------------------------
  # 残り日数を計算
  # ------------------------------------------
  # 【何をするメソッド？】
  # 期限までの残り日数を整数で返す。
  #
  # 【戻り値】
  # - 正の数: あと○日
  # - 0: 今日が期限
  # - 負の数: ○日過ぎている
  # - nil: 達成済みまたは期限なし
  #
  # 【to_i とは？】
  # 小数を整数に変換。Date同士の引き算は
  # Rationalという型になるため、整数に変換している。
  #
  def days_remaining
    return nil if achieved?      # 達成済みなら nil
    return nil if deadline.blank? # 期限がなければ nil

    (deadline - Date.current).to_i
  end

  # ------------------------------------------
  # 期限のステータスを取得
  # ------------------------------------------
  # 【何をするメソッド？】
  # 期限の状態をシンボルで返す。
  # UIでの色分け表示などに使用。
  #
  # 【戻り値の種類】
  # - :achieved - 達成済み（緑）
  # - :expired  - 期限切れ（赤）
  # - :today    - 今日が期限（オレンジ）
  # - :urgent   - 明日が期限（オレンジ）
  # - :warning  - 2〜3日以内（黄色）
  # - :normal   - 4日以上（グレー）
  #
  # 【case文とは？】
  # 値によって処理を分岐させる構文。
  # if-elsif の連続より読みやすい。
  #
  # 【2..3 とは？】
  # 範囲オブジェクト。2以上3以下を表す。
  # when 2..3 は「daysが2または3のとき」という意味。
  #
  def deadline_status
    days = days_remaining
    return :achieved if achieved?
    return :expired if days.nil? || days < 0

    case days
    when 0 then :today      # 今日が期限
    when 1 then :urgent     # 明日が期限
    when 2..3 then :warning # 2-3日以内
    else :normal            # 4日以上先
    end
  end

  # ==========================================
  # いいね関連メソッド
  # ==========================================

  # ------------------------------------------
  # 指定ユーザーがいいね済みか判定
  # ------------------------------------------
  # 【何をするメソッド？】
  # 指定されたユーザーがこのプランにいいねしているか確認。
  #
  # 【使用例（ビュー側）】
  # <% if @entry.liked_by?(current_user) %>
  #   <button disabled>いいね済み</button>
  # <% else %>
  #   <button>いいね</button>
  # <% end %>
  #
  def liked_by?(user)
    return false if user.nil?  # ログインしていなければ false
    entry_likes.exists?(user_id: user.id)
  end

  # ==========================================
  # S3署名付きURL関連メソッド
  # ==========================================
  #
  # 【署名付きURLとは？】
  # S3の非公開ファイルに一時的にアクセスできるURL。
  # 有効期限付きで、期限が切れるとアクセスできなくなる。
  # セキュリティのため、画像を直接公開せず署名付きURLを使う。
  #

  # ------------------------------------------
  # カスタムサムネイルの署名付きURLを取得
  # ------------------------------------------
  # 【何をするメソッド？】
  # アクションプラン作成時にアップロードした
  # カスタムサムネイル画像のURLを生成。
  #
  # 【戻り値】
  # - String: 署名付きURL（10分間有効）
  # - nil: サムネイルがない場合
  #
  def signed_thumbnail_url
    generate_signed_url(thumbnail_url)
  end

  # ------------------------------------------
  # 達成記録画像の署名付きURLを取得
  # ------------------------------------------
  # 【何をするメソッド？】
  # 達成報告時にアップロードした画像のURLを生成。
  #
  def signed_result_image_url
    generate_signed_url(result_image)
  end

  # ------------------------------------------
  # 達成記録表示用サムネイルURL
  # ------------------------------------------
  # 【何をするメソッド？】
  # 達成記録を表示する際のサムネイルURLを返す。
  # 複数のフォールバックを持つ。
  #
  # 【優先順位】
  # 1. 達成記録画像（あれば最優先）
  # 2. 投稿時のカスタムサムネイル
  # 3. YouTube動画のサムネイル（最終手段）
  #
  # 【|| とは？】
  # 左側が nil/false の場合、右側を返す。
  # A || B || C は「Aがあれば A、なければ B、なければ C」。
  #
  def display_result_thumbnail_url
    signed_result_image_url ||
      signed_thumbnail_url ||
      "https://i.ytimg.com/vi/#{post.youtube_video_id}/mqdefault.jpg"
  end

  # ------------------------------------------
  # 感想・画像付きで達成
  # ------------------------------------------
  # 【何をするメソッド？】
  # 振り返りコメントと達成記録画像を保存して、
  # アクションプランを達成済みにする。
  #
  # 【引数】
  # - reflection_text: 振り返りコメント（省略可）
  # - result_image_s3_key: 達成画像のS3キー（省略可）
  #
  # 【transaction とは？】
  # 複数の更新を「まとめて」実行する仕組み。
  # どれか1つでも失敗したら、全ての変更を取り消す。
  # これにより、データの整合性が保たれる。
  #
  def achieve_with_reflection!(reflection_text: nil, result_image_s3_key: nil)
    transaction do
      # 振り返りコメントをセット（あれば）
      self.reflection = reflection_text if reflection_text.present?

      # 達成画像のS3キーをセット（あれば）
      if result_image_s3_key.present?
        self.result_image = result_image_s3_key
      end

      # 達成日時をセット
      self.achieved_at = Time.current
      save!
    end
  end

  # ------------------------------------------
  # 感想の編集
  # ------------------------------------------
  # 達成後に振り返りコメントだけを編集する。
  #
  def update_reflection!(reflection_text:)
    update!(reflection: reflection_text)
  end

  private

  # ==========================================
  # プライベートメソッド（外部から呼べない）
  # ==========================================

  # ------------------------------------------
  # S3署名付きURLを生成（共通処理）
  # ------------------------------------------
  # 【何をするメソッド？】
  # S3に保存されたファイルの署名付きURLを生成する。
  # signed_thumbnail_url と signed_result_image_url から呼ばれる。
  #
  # 【引数】
  # - url_or_key: S3キー（例: "uploads/images/xxx.jpg"）
  #               または完全なURL
  # - expires_in: 有効期限（秒）。デフォルト600秒=10分
  #
  # 【処理の流れ】
  # 1. 空ならnilを返す
  # 2. URLからS3キーを抽出
  # 3. AWS SDKでS3に接続
  # 4. 署名付きURLを生成して返す
  #
  # 【rescue とは？】
  # エラーが発生した時の処理を書く。
  # ここではS3接続エラー時にnilを返す。
  #
  def generate_signed_url(url_or_key, expires_in: 600)
    return nil if url_or_key.blank?

    s3_key = extract_s3_key(url_or_key)
    return nil if s3_key.blank?

    # AWS S3クライアントを作成
    s3 = Aws::S3::Resource.new(
      region: ENV["AWS_REGION"],
      access_key_id: ENV["AWS_ACCESS_KEY_ID"],
      secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"]
    )

    # 署名付きURLを生成
    # :get は「読み取り用」という意味
    s3.bucket(ENV["AWS_BUCKET"]).object(s3_key).presigned_url(:get, expires_in: expires_in)
  rescue Aws::S3::Errors::ServiceError
    # S3でエラーが発生した場合はnilを返す
    nil
  end

  # ------------------------------------------
  # S3キーを抽出
  # ------------------------------------------
  # 【何をするメソッド？】
  # 完全なURLからS3キー部分を取り出す。
  # すでにキーだけの場合はそのまま返す。
  #
  # 【例】
  # 入力: "https://bucket.s3.region.amazonaws.com/path/to/file.png"
  # 出力: "path/to/file.png"
  #
  # 入力: "path/to/file.png"
  # 出力: "path/to/file.png"（そのまま）
  #
  # 【URI.parse(url).path とは？】
  # URLをパースして、パス部分（/path/to/file.png）を取得。
  # [1..] で先頭の "/" を除去する。
  #
  def extract_s3_key(url)
    return url unless url.start_with?("http://", "https://")

    URI.parse(url).path[1..]
  rescue URI::InvalidURIError
    nil
  end

  # ------------------------------------------
  # 期限を自動設定
  # ------------------------------------------
  # 【何をするメソッド？】
  # 期限が指定されていない場合、
  # 作成日から7日後を自動でセットする。
  #
  # 【||= とは？】
  # 左辺が nil または false の場合のみ、右辺を代入する。
  # self.deadline ||= X は以下と同じ:
  #   if self.deadline.nil?
  #     self.deadline = X
  #   end
  #
  # 【7.days とは？】
  # Railsが提供する便利な書き方。7日間を表す。
  # Date.current + 7.days で「今日から7日後」。
  #
  def set_auto_deadline
    self.deadline ||= Date.current + 7.days
  end

  # ------------------------------------------
  # ユーザー全体で未達成アクションは1つのみ
  # ------------------------------------------
  # 【何をするメソッド？】
  # 同じユーザーが未達成のアクションプランを
  # 2つ以上持てないようにする。
  #
  # 【なぜこのルールがあるか？】
  # 1つのことに集中して達成することを促すため。
  # 複数のプランを同時に持つと、どれも中途半端になりがち。
  #
  # 【errors.add とは？】
  # バリデーションエラーを追加する。
  # :base は「特定のカラムではなく全体に対するエラー」を意味する。
  #
  def one_incomplete_action_per_user
    return if user.blank?

    existing = PostEntry.not_achieved.where(user: user).first
    if existing.present?
      errors.add(:base, "未達成のアクションプランがあります。達成してから新しいプランを投稿してください")
    end
  end
end
