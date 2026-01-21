// app/javascript/controllers/index.js
// Stimulusコントローラーの自動読み込み設定
//
// このファイルは controllers/ フォルダ内の全コントローラーを
// 自動的に読み込んで Stimulus に登録する
//
// ファイル名の規則:
// - xxx_controller.js → data-controller="xxx" として使用可能
// - 例: flash_controller.js → data-controller="flash"

import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
eagerLoadControllersFrom("controllers", application)
