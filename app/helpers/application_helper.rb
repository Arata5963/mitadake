# アプリケーション共通ヘルパー
# 全ビューで使用できる共通メソッドを定義

module ApplicationHelper
  # ユーザー表示名を返す（未設定なら「名無しさん」）
  def display_name(user)
    user.name.presence || "名無しさん"  # presenceはblank判定
  end

  # OGP・メタタグのデフォルト設定を返す
  def default_meta_tags
    {
      site: "mitadake?",                 # サイト名
      title: "",                         # ページタイトル（各ページで上書き）
      reverse: true,                     # 「ページ名 | サイト名」形式
      charset: "utf-8",                  # 文字エンコーディング
      description: "YouTube動画から得た学びを具体的なアクションに変換。見て終わりを、やってみるに変える。",
      keywords: "YouTube,学習,行動,習慣,目標達成,自己改善,アクションプラン",
      canonical: request.original_url,   # 正規URL（SEO対策）
      separator: "|",                    # タイトル区切り文字

      og: {                              # Facebook, LINE等向け
        site_name: "mitadake?",
        title: :title,                   # 上のtitle設定を参照
        description: :description,
        type: "website",
        url: request.original_url,
        image: "#{request.base_url}/ogp-image.png",
        locale: "ja_JP"
      },

      twitter: {                         # Twitter Card向け
        card: "summary_large_image",     # 大きい画像付きカード形式
        title: :title,
        description: :description,
        image: "#{request.base_url}/ogp-image.png"
      }
    }
  end
end
