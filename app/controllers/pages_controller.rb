# 静的ページコントローラー
# 利用規約・プライバシーポリシーなど固定ページを表示

class PagesController < ApplicationController
  # トップページ（ルート）
  def home
    if user_signed_in?                                     # ログイン済みの場合
      redirect_to posts_path                               # 投稿一覧へリダイレクト
    else                                                   # 未ログインの場合
      render :lp_minimal_full, layout: "landing"           # LPを表示
    end
  end

  # 利用規約ページ
  def terms
    # 自動的に app/views/pages/terms.html.erb が表示される
  end

  # プライバシーポリシーページ
  def privacy
    # 自動的に app/views/pages/privacy.html.erb が表示される
  end
end
