# app/models/application_record.rb
# 全モデルの基底クラス
# アプリ全体で共通のメソッドやスコープを定義する場所
# 現在は特別な機能は追加していない
class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class
end
