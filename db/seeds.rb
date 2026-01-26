# db/seeds.rb
# ==========================================
# 初期データ投入スクリプト
# ==========================================
#
# 【実行方法】
#   docker compose exec web rails db:seed:replant  # 全削除 + seed実行
#
# 【作成されるデータ】
#   - テストユーザー: 10人（Aさん〜Jさん）
#   - 投稿データ: なし（手動で作成する）
#
# 【ログイン情報】
#   全ユーザー共通パスワード: password
#
# ==========================================

puts "Seeding database..."

# 既存データをクリア
puts "Clearing existing data..."

tables_to_clear = %w[
  entry_likes
  post_entries
  posts
  users
]

tables_to_clear.each do |table|
  puts "  Deleting #{table}..."
  ActiveRecord::Base.connection.execute("DELETE FROM #{table}") rescue nil
end

# ===== テストユーザー作成（Aさん〜Jさん） =====
puts "Creating test users..."

test_users = ("A".."J").map.with_index do |letter, index|
  User.create!(
    email: "#{letter.downcase}@test.com",
    password: "password",
    name: "#{letter}さん"
  )
end

puts ""
puts "=" * 50
puts "Seeding completed!"
puts "=" * 50
puts ""
puts "Test users created:"
test_users.each do |user|
  puts "  #{user.name}: #{user.email} / password"
end
puts ""
puts "Total users: #{User.count}"
puts ""
