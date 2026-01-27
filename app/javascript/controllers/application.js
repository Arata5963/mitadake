// Stimulusアプリケーションの初期化
// 全コントローラーの起点となる設定ファイル

import { Application } from "@hotwired/stimulus"              // Stimulusフレームワーク
import { Autocomplete } from "stimulus-autocomplete"          // オートコンプリートライブラリ

const application = Application.start()                        // Stimulusを起動
application.register("autocomplete", Autocomplete)             // autocompleteコントローラーを登録
application.debug = false                                      // デバッグログを無効化
window.Stimulus   = application                                // グローバル変数として公開（デバッグ用）

export { application }                                         // 他ファイルから参照可能にする
