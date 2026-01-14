# db/seeds.rb
# マイページ表示確認用のテストデータ

puts "Seeding database..."

# 既存データをクリア
puts "Clearing existing data..."
ActivityNotification::Notification.destroy_all rescue nil
Cheer.destroy_all
Achievement.destroy_all
PostEntry.destroy_all
Post.destroy_all
FavoriteVideo.destroy_all
User.destroy_all

# メインユーザー作成（favorite_quoteは後でPost作成後に設定）
puts "Creating main user..."
main_user = User.create!(
  email: "test@example.com",
  password: "password123",
  name: "あらた",
  remote_avatar_url: "https://i.pravatar.cc/300?img=12"
)
main_user_quote = "継続は力なり。毎日少しずつでも前に進もう。"

# 他のユーザー作成（ランキング用）- 引用URLは後で設定
puts "Creating other users..."
users = []
user_data = [
  { name: "さくら", quote: "夢は逃げない。逃げるのはいつも自分だ。", avatar_id: 5, video_index: 0 },
  { name: "ゆうき", quote: "失敗を恐れるな、挑戦しないことを恐れろ。", avatar_id: 33, video_index: 1 },
  { name: "はると", quote: "今日という日は、残りの人生の最初の日。", avatar_id: 51, video_index: 2 },
  { name: "めい", quote: "小さな一歩が大きな変化を生む。", avatar_id: 9, video_index: 3 },
  { name: "そうた", quote: nil, avatar_id: 60, video_index: nil }
]

user_data.each_with_index do |data, i|
  users << User.create!(
    email: "user#{i+1}@example.com",
    password: "password123",
    name: data[:name],
    # favorite_quote/favorite_quote_url は後でPostを作成してから設定
    remote_avatar_url: "https://i.pravatar.cc/300?img=#{data[:avatar_id]}"
  )
end

# YouTube動画サンプル（実際の動画）
youtube_videos = [
  {
    url: "https://www.youtube.com/watch?v=R1vskiVDwl4",
    video_id: "R1vskiVDwl4",
    title: "Why You Should Want to Suffer",
    channel: "Veritasium"
  },
  {
    url: "https://www.youtube.com/watch?v=arj7oStGLkU",
    video_id: "arj7oStGLkU",
    title: "Steve Jobs' 2005 Stanford Commencement Address",
    channel: "Stanford"
  },
  {
    url: "https://www.youtube.com/watch?v=UF8uR6Z6KLc",
    video_id: "UF8uR6Z6KLc",
    title: "Steve Jobs introduces iPhone in 2007",
    channel: "John Schroter"
  },
  {
    url: "https://www.youtube.com/watch?v=Hc6J0vrKTPM",
    video_id: "Hc6J0vrKTPM",
    title: "中田敦彦のYouTube大学 - お金の授業",
    channel: "中田敦彦のYouTube大学"
  },
  {
    url: "https://www.youtube.com/watch?v=5MgBikgcWnY",
    video_id: "5MgBikgcWnY",
    title: "The power of introverts | Susan Cain | TED",
    channel: "TED"
  },
  {
    url: "https://www.youtube.com/watch?v=H14bBuluwB8",
    video_id: "H14bBuluwB8",
    title: "Atomic Habits - James Clear",
    channel: "Productivity Game"
  },
  {
    url: "https://www.youtube.com/watch?v=75d_29QWELk",
    video_id: "75d_29QWELk",
    title: "ひろゆき 人生についてのアドバイス",
    channel: "ひろゆき切り抜き"
  }
]

# 投稿とアクションプラン作成
puts "Creating posts and action plans..."

posts = youtube_videos.map do |video|
  Post.create!(
    user: main_user,
    youtube_url: video[:url],
    youtube_video_id: video[:video_id],
    youtube_title: video[:title],
    youtube_channel_name: video[:channel]
  )
end

# ユーザーの favorite_quote と favorite_quote_url を実際のPostのURLで更新
puts "Updating user favorite quotes..."

# メインユーザー（Atomic Habitsの動画を使用）
main_user.update!(
  favorite_quote: main_user_quote,
  favorite_quote_url: youtube_videos[5][:url]
)

# 他のユーザー（引用とURLをセットで更新）
users.each_with_index do |user, i|
  video_index = user_data[i][:video_index]
  quote = user_data[i][:quote]
  if video_index && quote.present?
    user.update!(
      favorite_quote: quote,
      favorite_quote_url: youtube_videos[video_index][:url]
    )
  end
end

# メインユーザーのアクションプラン（やること）
action_plans = [
  # 今日が期限
  { post: posts[0], content: "明日から5時に起きる習慣をスタートする", deadline: Date.current, achieved: false },
  # 明日が期限
  { post: posts[0], content: "目覚まし時計を寝室から離れた場所に置く", deadline: Date.current + 1.day, achieved: false },
  # 3日後
  { post: posts[1], content: "Progateでプログラミング基礎を学ぶ", deadline: Date.current + 3.days, achieved: false },
  # 1週間後
  { post: posts[2], content: "週3回、20分の筋トレを行う", deadline: Date.current + 7.days, achieved: false },
  # 期限切れ
  { post: posts[3], content: "英語のポッドキャストを毎日聞く", deadline: Date.current - 2.days, achieved: false },
]

# 達成済みのアクションプラン（やったこと）
completed_plans = [
  { post: posts[4], content: "週末に作り置きレシピを3品作る", deadline: Date.current - 5.days, achieved: true },
  { post: posts[5], content: "毎日寝る前に15分読書する", deadline: Date.current - 3.days, achieved: true },
  { post: posts[5], content: "読書メモをNotionに記録する", deadline: Date.current - 1.day, achieved: true },
  { post: posts[6], content: "朝起きたら5分間瞑想する", deadline: Date.current - 4.days, achieved: true },
]

# アクションプラン作成（バリデーションをスキップ）
action_plans.each do |plan|
  entry = PostEntry.new(
    post: plan[:post],
    user: main_user,
    content: plan[:content],
    deadline: plan[:deadline],
    achieved_at: nil
  )
  entry.save!(validate: false)
end

completed_plans.each do |plan|
  entry = PostEntry.new(
    post: plan[:post],
    user: main_user,
    content: plan[:content],
    deadline: plan[:deadline],
    achieved_at: Time.current - rand(1..5).days
  )
  entry.save!(validate: false)
end

# 他ユーザーの達成数を作成（ランキング用）
puts "Creating achievements for ranking..."
achievement_counts = [15, 12, 8, 5, 3]

users.each_with_index do |user, i|
  count = achievement_counts[i] || 1

  # 各ユーザー用の投稿とアクションプランを作成（バリデーションスキップ）
  count.times do |j|
    post = posts.sample
    entry = PostEntry.new(
      post: post,
      user: user,
      content: "アクションプラン #{j+1}",
      deadline: Date.current - rand(1..30).days,
      achieved_at: Time.current - rand(1..30).days
    )
    entry.save!(validate: false)
  end
end

# 応援を作成（通知テスト用）
puts "Creating cheers..."
users.first(3).each do |user|
  Cheer.create!(user: user, post: posts.first)
end

puts ""
puts "=" * 50
puts "Seeding completed!"
puts "=" * 50
puts ""
puts "Login credentials:"
puts "  Email: test@example.com"
puts "  Password: password123"
puts ""
puts "Summary:"
puts "  Users: #{User.count}"
puts "  Posts: #{Post.count}"
puts "  Action Plans (pending): #{PostEntry.not_achieved.where(user: main_user).count}"
puts "  Action Plans (completed): #{PostEntry.achieved.where(user: main_user).count}"
puts "  Cheers: #{Cheer.count}"
puts ""
