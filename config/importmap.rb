# JavaScriptモジュール管理（Import Maps）
# Node.js/npmなしでJSライブラリを管理する仕組み

pin "application"  # エントリーポイント

# Hotwire（Turbo + Stimulus）
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "@hotwired--stimulus.js"  # @3.2.2
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"

# Stimulusコントローラー・ユーティリティ
pin_all_from "app/javascript/controllers", under: "controllers"
pin_all_from "app/javascript/utils", under: "utils"

# 外部ライブラリ
pin "stimulus-autocomplete"  # @3.1.0 入力補完機能
