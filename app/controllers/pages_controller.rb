# app/controllers/pages_controller.rb
# ==========================================
# 静的ページ用コントローラー
# ==========================================
#
# 【このクラスの役割】
# 利用規約・プライバシーポリシーなど、
# データベースを使わない固定ページを表示する。
#
# 【静的ページとは？】
# 内容が固定されていて、ユーザーによって変わらないページ。
# 対義語は「動的ページ」（ユーザーごとに内容が変わる）。
#
# 【なぜコントローラーが必要か？】
# Railsでは、どんなページもコントローラー経由で表示する。
# 中身が空でも、ルーティングとビューを繋ぐ役割がある。
#
# 【対応するビュー】
# - terms  → app/views/pages/terms.html.erb
# - privacy → app/views/pages/privacy.html.erb
# - lp_minimal_full → app/views/pages/lp_minimal_full.html.erb (LP)
#
class PagesController < ApplicationController
  # ------------------------------------------
  # トップページ（ルート）
  # ------------------------------------------
  # 【ルート】GET /
  #
  # ログイン状態によって表示を切り替える:
  # - 未ログイン → LP表示
  # - ログイン済み → 投稿一覧へリダイレクト
  #
  def home
    if user_signed_in?
      redirect_to posts_path
    else
      render :lp_minimal_full, layout: "landing"
    end
  end
  # ------------------------------------------
  # 利用規約ページ
  # ------------------------------------------
  # 【ルート】GET /terms
  #
  # 【処理内容】
  # 何もしない（空のアクション）。
  # Railsは自動的に views/pages/terms.html.erb を表示する。
  #
  # 【なぜ空なのか？】
  # 静的ページなのでデータベースへのアクセスが不要。
  # ビューさえあれば、コントローラーは空でOK。
  #
  def terms
    # 自動的に app/views/pages/terms.html.erb が表示される
  end

  # ------------------------------------------
  # プライバシーポリシーページ
  # ------------------------------------------
  # 【ルート】GET /privacy
  #
  def privacy
    # 自動的に app/views/pages/privacy.html.erb が表示される
  end

end
