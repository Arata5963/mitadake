// app/javascript/controllers/application.js
// Stimulusアプリケーションの初期化
// 全コントローラーの起点となるファイル
//
// 主な設定:
// - Stimulusアプリケーションの起動
// - stimulus-autocomplete ライブラリの登録（検索フォーム用）
// - デバッグモードの設定（本番では false）

import { Application } from "@hotwired/stimulus"
import { Autocomplete } from "stimulus-autocomplete"

const application = Application.start()
application.register("autocomplete", Autocomplete)

// デバッグモード設定（開発時は true にすると詳細ログが出力される）
application.debug = false
window.Stimulus   = application

export { application }
