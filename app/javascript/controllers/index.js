// Stimulusコントローラーの自動読み込み設定
// controllersフォルダ内の全コントローラーを自動登録する

import { application } from "controllers/application"          // Stimulusアプリケーション
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"  // 自動読み込み機能

eagerLoadControllersFrom("controllers", application)           // 全コントローラーを即座に読み込み
