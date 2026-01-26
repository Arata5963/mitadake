# app/controllers/dev_controller.rb
# ==========================================
# 開発環境専用コントローラー
# ==========================================
#
# 【このコントローラーの役割】
# 開発時のみ使用するユーティリティ機能を提供。
# 本番環境では一切動作しない（development_only で保護）。
#
# 【機能】
# - switch_user: テストユーザーへの切り替え（なりすまし）
#
class DevController < ApplicationController
  before_action :development_only

  # ユーザー切り替え（なりすまし）
  def switch_user
    user = User.find(params[:user_id])
    sign_in(user)
    redirect_to mypage_path, notice: "#{user.name}に切り替えました"
  end

  private

  # 開発環境以外ではアクセス禁止
  def development_only
    head :forbidden unless Rails.env.development?
  end
end
