# app/models/entry_flame.rb
class EntryFlame < ApplicationRecord
  # ===== アソシエーション =====
  belongs_to :user
  belongs_to :post_entry

  # ===== 通知設定 =====
  # 炎マーク時にアクションプラン投稿者に通知を送る（自分には通知しない）
  acts_as_notifiable :users,
    targets: ->(flame, _key) {
      return [] if flame.post_entry.user.nil?
      return [] if flame.user == flame.post_entry.user
      [ flame.post_entry.user ]
    },
    group: :post_entry,
    notifier: :user,
    email_allowed: false,
    notifiable_path: :post_path_for_notification

  # ===== コールバック =====
  after_create :send_notification

  # ===== バリデーション =====
  # 同じユーザーが同じアクションプランに重複して炎を付けられないようにする
  validates :user_id, uniqueness: { scope: :post_entry_id }

  private

  def post_path_for_notification
    Rails.application.routes.url_helpers.post_path(post_entry.post)
  end

  def send_notification
    notify :users if user != post_entry.user
  end
end
