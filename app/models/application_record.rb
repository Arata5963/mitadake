# 全モデルの基底クラス
# アプリ全体で共通のメソッドやスコープを定義する場所

class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class  # 抽象クラスとして宣言（直接インスタンス化しない）
end
