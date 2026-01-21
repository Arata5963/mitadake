# app/helpers/application_helper.rb
# 全ビューで使用可能なヘルパーメソッドを定義
#
# 主な機能:
# - ユーザー表示名のフォールバック処理
# - OGP/メタタグのデフォルト設定
module ApplicationHelper
  # ユーザー表示名を返す
  # @param user [User] ユーザー
  # @return [String] ユーザー名、または「名無しさん」
  def display_name(user)
    user.name.presence || "名無しさん"
  end

  # OGP・メタタグのデフォルト設定を返す
  # meta-tags gem で使用
  # @return [Hash] メタタグ設定ハッシュ
  # @see https://github.com/kpumuk/meta-tags
  def default_meta_tags
    {
      site: "mitadake?",
      title: "",
      reverse: true,                    # タイトルを「ページ名 | サイト名」の形式に
      charset: "utf-8",
      description: "YouTube動画から得た学びを具体的なアクションに変換。見て終わりを、やってみるに変える。",
      keywords: "YouTube,学習,行動,習慣,目標達成,自己改善,アクションプラン",
      canonical: request.original_url,  # 正規URLを設定（SEO対策）
      separator: "|",
      # Facebook/LINE等のOGP設定
      og: {
        site_name: "mitadake?",
        title: :title,                  # :titleでタイトルを自動参照
        description: :description,
        type: "website",
        url: request.original_url,
        image: "#{request.base_url}/ogp-image.png",
        locale: "ja_JP"
      },
      # Twitter Card設定
      twitter: {
        card: "summary_large_image",    # 大きい画像付きカード
        title: :title,
        description: :description,
        image: "#{request.base_url}/ogp-image.png"
      }
    }
  end
end
