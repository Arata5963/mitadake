# config/initializers/inflections.rb
# ==========================================
# 活用形（Inflection）設定
# ==========================================
#
# 【このファイルの役割】
# Railsが単語の単数形・複数形を変換する際のルールを
# カスタマイズする。
#
# 【Inflection（活用形）とは？】
# Railsはモデル名からテーブル名を自動生成する際に
# 英語の複数形変換ルールを使用する。
#
#   User   → users    (通常の複数形)
#   Person → people   (不規則変化)
#   News   → news     (不可算名詞)
#
# 【なぜカスタマイズが必要？】
# 日本語のサービスでは英語以外の単語や
# 特殊な変化をする単語を使うことがある。
#
# 例: "mitadake" → "mitadakes" にしたくない場合
#     inflect.uncountable "mitadake" と設定
#
# 【現在の状態】
# このファイルでは全てコメントアウトされている（デフォルト）。
# 必要に応じてカスタムルールを追加する。
#
# Be sure to restart your server when you modify this file.

# ------------------------------------------
# 活用形ルールの設定例
# ------------------------------------------
# 【各メソッドの意味】
#
# inflect.plural:      単数形 → 複数形のルール
# inflect.singular:    複数形 → 単数形のルール
# inflect.irregular:   不規則変化（person → people など）
# inflect.uncountable: 複数形にしない単語（fish, news など）
# inflect.acronym:     頭字語の大文字維持（API, HTML など）
#
# Add new inflection rules using the following format. Inflections
# are locale specific, and you may define rules for as many different
# locales as you wish. All of these examples are active by default:
# ActiveSupport::Inflector.inflections(:en) do |inflect|
#   inflect.plural /^(ox)$/i, "\\1en"
#   inflect.singular /^(ox)en/i, "\\1"
#   inflect.irregular "person", "people"
#   inflect.uncountable %w( fish sheep )
# end

# These inflection rules are supported but not enabled by default:
# ActiveSupport::Inflector.inflections(:en) do |inflect|
#   inflect.acronym "RESTful"
# end
