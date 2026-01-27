# 初期データ投入スクリプト
# rails db:seed:replant でテストユーザー（A〜Jさん）を作成

puts "Seeding database..."

puts "Clearing existing data..."
tables_to_clear = %w[entry_likes post_entries posts users]
tables_to_clear.each do |table|
  puts "  Deleting #{table}..."
  ActiveRecord::Base.connection.execute("DELETE FROM #{table}") rescue nil
end

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
