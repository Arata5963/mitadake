# app/helpers/application_helper.rb
# ==========================================
# アプリケーション共通ヘルパー
# ==========================================
#
# 【このファイルの役割】
# 全てのビュー（ERBテンプレート）で使用できる
# ヘルパーメソッドを定義する。
#
# 【ヘルパーとは？】
# ビューで使う便利なメソッドをまとめたもの。
# コントローラーやモデルに書くと冗長になる処理を
# ここに切り出すことで、ビューをすっきりさせる。
#
# 【使用例（ビュー内で）】
#   <%= display_name(@user) %>
#   → ユーザー名または「名無しさん」を表示
#
# 【主な機能】
# 1. display_name: ユーザー表示名のフォールバック
# 2. default_meta_tags: OGP/SEOメタタグのデフォルト設定
#
module ApplicationHelper

  # ------------------------------------------
  # ユーザー表示名を返す
  # ------------------------------------------
  # 【何をするメソッド？】
  # ユーザー名が設定されていればそれを返し、
  # 未設定なら「名無しさん」を返す。
  #
  # 【なぜ必要？】
  # Google OAuth でログインした場合、名前が取得できないことがある。
  # その場合でもエラーにならずに表示できるようにする。
  #
  # 【引数】
  # @param user [User] ユーザーオブジェクト
  #
  # 【戻り値】
  # @return [String] ユーザー名、または「名無しさん」
  #
  # 【使用例】
  #   display_name(@user)
  #   # => "山田太郎" または "名無しさん"
  #
  # 【.presence とは？】
  # 空文字列("")やnilの場合はnilを返し、
  # 値がある場合はその値を返すRailsのメソッド。
  # || と組み合わせてフォールバック値を設定できる。
  #
  def display_name(user)
    user.name.presence || "名無しさん"
  end

  # ------------------------------------------
  # OGP・メタタグのデフォルト設定
  # ------------------------------------------
  # 【何をするメソッド？】
  # SNS共有時やSEO対策に使うメタタグの
  # デフォルト値を設定する。
  #
  # 【OGP（Open Graph Protocol）とは？】
  # Facebook, LINE, Twitterなどで共有された時に
  # 表示されるタイトル・説明・画像を指定する仕組み。
  #
  # 【meta-tags gem】
  # このメソッドは meta-tags gem で使用される。
  # app/views/layouts/application.html.erb で
  # <%= display_meta_tags(default_meta_tags) %> と呼ばれる。
  #
  # 【戻り値】
  # @return [Hash] メタタグ設定のハッシュ
  #
  # 【参考】
  # @see https://github.com/kpumuk/meta-tags
  #
  def default_meta_tags
    {
      # ------------------------------------------
      # 基本設定
      # ------------------------------------------
      site: "mitadake?",                  # サイト名
      title: "",                          # ページタイトル（各ページで上書き）
      reverse: true,                      # 「ページ名 | サイト名」の形式にする
      charset: "utf-8",                   # 文字エンコーディング
      description: "YouTube動画から得た学びを具体的なアクションに変換。見て終わりを、やってみるに変える。",
      keywords: "YouTube,学習,行動,習慣,目標達成,自己改善,アクションプラン",
      canonical: request.original_url,    # 正規URL（SEO：重複コンテンツ対策）
      separator: "|",                     # タイトルの区切り文字

      # ------------------------------------------
      # OGP設定（Facebook, LINE等）
      # ------------------------------------------
      og: {
        site_name: "mitadake?",
        title: :title,                    # :title = 上のtitle設定を参照
        description: :description,
        type: "website",
        url: request.original_url,
        image: "#{request.base_url}/ogp-image.png",  # 共有時に表示される画像
        locale: "ja_JP"
      },

      # ------------------------------------------
      # Twitter Card設定
      # ------------------------------------------
      twitter: {
        card: "summary_large_image",      # 大きい画像付きカード形式
        title: :title,
        description: :description,
        image: "#{request.base_url}/ogp-image.png"
      }
    }
  end
end
