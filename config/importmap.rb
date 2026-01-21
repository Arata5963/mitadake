# config/importmap.rb
# ==========================================
# JavaScript モジュール管理（Import Maps）
# ==========================================
#
# 【Import Mapsとは？】
# Node.js/npm を使わずにJavaScriptライブラリを管理する仕組み。
# Rails 7 からの新機能で、ブラウザの ES Modules を活用する。
#
# 【従来の方法との違い】
#   Webpack/esbuild: npm install → バンドル → 配信
#   Import Maps:     CDNから直接読み込み or vendor/に配置
#
# 【基本的な書き方】
#   pin "ライブラリ名"                    # CDNから取得
#   pin "名前", to: "ファイル.js"         # 別名で参照
#   pin_all_from "フォルダ", under: "名前" # フォルダ内の全JSを登録
#
# 【よく使うコマンド】
#   ./bin/importmap pin ライブラリ名     # ライブラリを追加
#   ./bin/importmap unpin ライブラリ名   # ライブラリを削除
#   ./bin/importmap update              # バージョンを更新
#   ./bin/importmap json                # 現在の設定をJSON出力
#
# 【JavaScript側での使い方】
#   import { Controller } from "@hotwired/stimulus"
#   import flatpickr from "flatpickr"
#
# ==========================================

# ===== アプリケーション本体 =====
# app/javascript/application.js をエントリーポイントとして登録
pin "application"

# ===== Hotwire（Turbo + Stimulus）=====
# Turbo: ページ遷移を高速化（SPAのような動作）
pin "@hotwired/turbo-rails", to: "turbo.min.js"

# Stimulus: シンプルなJavaScriptフレームワーク
pin "@hotwired/stimulus", to: "@hotwired--stimulus.js" # @3.2.2
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"

# ===== Stimulusコントローラー =====
# app/javascript/controllers/ 内の全ファイルを自動登録
pin_all_from "app/javascript/controllers", under: "controllers"

# ===== ユーティリティ関数 =====
# app/javascript/utils/ 内の全ファイルを自動登録
pin_all_from "app/javascript/utils", under: "utils"

# ===== 外部ライブラリ =====
# stimulus-autocomplete: 入力補完機能
pin "stimulus-autocomplete" # @3.1.0

# flatpickr: 日付選択カレンダー

# marked: Markdown → HTML 変換
