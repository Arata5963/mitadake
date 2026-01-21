// app/javascript/application.js
// ==========================================
// JavaScriptアプリケーションのエントリーポイント
// ==========================================
//
// 【このファイルの役割】
// Railsアプリ全体で使用するJavaScriptの読み込み起点。
// app/views/layouts/application.html.erb の javascript_importmap_tags で
// 自動的に読み込まれる。
//
// 【Importmapとは？】
// Rails 7で採用されたJavaScript管理方式。
// config/importmap.rb でライブラリの読み込み先を定義する。
// webpackやesbuildを使わず、ブラウザのネイティブ機能で
// モジュールを読み込む仕組み。
//
// 【読み込まれるもの】
// 1. @hotwired/turbo-rails: Turbo Drive/Frames/Streams
//    - ページ遷移を高速化（SPAライクな体験）
//    - フォーム送信のAJAX化
//    - 部分的なページ更新
//
// 2. controllers: Stimulusコントローラー
//    - app/javascript/controllers/ 以下の全ファイル
//    - DOM操作、イベントハンドリング
//

// Turbo Driveの読み込み（ページ遷移の高速化）
import "@hotwired/turbo-rails"

// Stimulusコントローラーの読み込み
import "controllers"
