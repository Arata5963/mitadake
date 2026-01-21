# app/controllers/pages_controller.rb
# 静的ページ用コントローラー
# 利用規約・プライバシーポリシーなどの固定ページを表示
class PagesController < ApplicationController
  # 利用規約ページ
  # @route GET /terms
  def terms
  end

  # プライバシーポリシーページ
  # @route GET /privacy
  def privacy
  end
end
