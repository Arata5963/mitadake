// app/javascript/controllers/index.js
// ==========================================
// Stimulusコントローラーの自動読み込み設定
// ==========================================
//
// 【このファイルの役割】
// controllers/ フォルダ内の全コントローラーを
// 自動的に読み込んで Stimulus に登録する。
// 新しいコントローラーを追加しても、ここを編集する必要はない。
//
// 【ファイル名の規則】
// ファイル名が data-controller の値になる
//
//   ファイル名                    →  data-controller の値
//   ─────────────────────────────────────────────────────
//   flash_controller.js          →  "flash"
//   post_create_controller.js    →  "post-create"
//   achievement_modal_controller.js → "achievement-modal"
//
// 【使い方の例】
//   <!-- HTML -->
//   <div data-controller="flash">
//     ↓
//   flash_controller.js の connect() が呼ばれる
//
// 【eagerLoadControllersFrom とは？】
// Stimulusの機能で、指定フォルダ内の *_controller.js を
// 全て自動で読み込んで登録する。
// "eager" = 即座に、という意味。
//

import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"

// controllers/ フォルダ内の全コントローラーを読み込み
eagerLoadControllersFrom("controllers", application)
