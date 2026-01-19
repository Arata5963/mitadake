# db/seeds.rb
# 実際に使われそうなテストデータ

puts "Seeding database..."

# 既存データをクリア（外部キー依存順序でDELETE）
puts "Clearing existing data..."

tables_to_clear = %w[
  entry_flames
  comment_bookmarks
  post_comparisons
  recommendation_clicks
  youtube_comments
  notifications
  subscriptions
  comments
  cheers
  achievements
  post_entries
  posts
  favorite_videos
  users
]

tables_to_clear.each do |table|
  puts "  Deleting #{table}..."
  ActiveRecord::Base.connection.execute("DELETE FROM #{table}") rescue nil
end

# ===== ユーザー作成 =====
puts "Creating users..."

main_user = User.create!(
  email: "test@example.com",
  password: "password123",
  name: "あらた",
  remote_avatar_url: "https://i.pravatar.cc/300?img=12"
)

other_users = [
  { name: "さくら", email: "sakura@example.com", avatar_id: 5 },
  { name: "ゆうき", email: "yuuki@example.com", avatar_id: 33 },
  { name: "はると", email: "haruto@example.com", avatar_id: 51 },
  { name: "めい", email: "mei@example.com", avatar_id: 9 },
  { name: "そうた", email: "souta@example.com", avatar_id: 60 },
  { name: "りな", email: "rina@example.com", avatar_id: 21 },
  { name: "けんた", email: "kenta@example.com", avatar_id: 68 },
].map do |data|
  User.create!(
    email: data[:email],
    password: "password123",
    name: data[:name],
    remote_avatar_url: "https://i.pravatar.cc/300?img=#{data[:avatar_id]}"
  )
end

all_users = [main_user] + other_users

# ===== YouTube動画データ（実際の日本の人気動画） =====
youtube_videos = [
  # 中田敦彦のYouTube大学
  {
    video_id: "Hc6J0vrKTPM",
    title: "中田敦彦のYouTube大学 - お金の授業",
    channel: "中田敦彦のYouTube大学 - NAKATA UNIVERSITY"
  },
  {
    video_id: "4fig6UxBJkM",
    title: "【7つの習慣①】不滅の名著！成功の鍵は継続する習慣だ",
    channel: "中田敦彦のYouTube大学 - NAKATA UNIVERSITY"
  },
  {
    video_id: "kX-S8JKoB6A",
    title: "【嫌われる勇気①】承認欲求を否定せよ",
    channel: "中田敦彦のYouTube大学 - NAKATA UNIVERSITY"
  },
  # マコなり社長
  {
    video_id: "EYSeCV1hSgc",
    title: "【厳選】生産性を極めた社長の1日ルーティン",
    channel: "マコなり社長"
  },
  {
    video_id: "9zCs9X7N5po",
    title: "【毎日が楽園】マイナス思考から一瞬で抜け出す方法 TOP３",
    channel: "マコなり社長"
  },
  {
    video_id: "2IjqXp120Wg",
    title: "【決定版】汚い家の特徴 & 究極の改善策 20選",
    channel: "マコなり社長"
  },
  # TED
  {
    video_id: "H14bBuluwB8",
    title: "Grit: The Power of Passion and Perseverance | Angela Lee Duckworth | TED",
    channel: "TED"
  },
  {
    video_id: "bYBblm1RKsQ",
    title: "Inside the Mind of a Master Procrastinator | Tim Urban | TED",
    channel: "TED"
  },
  {
    video_id: "R1vskiVDwl4",
    title: "Celeste Headlee: 10 ways to have a better conversation | TED",
    channel: "TED"
  },
  # Kurzgesagt（人気の解説動画）
  {
    video_id: "75d_29QWELk",
    title: "Change Your Life – One Tiny Step at a Time",
    channel: "Kurzgesagt – In a Nutshell"
  },
  # TEDx Talks
  {
    video_id: "5MgBikgcWnY",
    title: "The first 20 hours -- how to learn anything | Josh Kaufman | TEDxCSU",
    channel: "TEDx Talks"
  },
  # Paranoia_パラノイア
  {
    video_id: "RJHemCEvXJA",
    title: "【実践済み】海外でaa億回再生された話題のプログラム「ウィン・・・",
    channel: "Paranoia_パラノイア【有益】"
  },
  {
    video_id: "tDtcihGvNnY",
    title: "個人で10億以上稼ぐ男クリス・コーナー「ゼロから稼ぐなら、まず何をする？」",
    channel: "Paranoia_パラノイア【有益】"
  },
  # ジョージ・メンズコーチ
  {
    video_id: "Z7Cs6SqMPFs",
    title: "危機感が全て。お前最後に凍張ったのいつ？",
    channel: "ジョージ・メンズコーチ-"
  },
  {
    video_id: "YjC-M5c_KZg",
    title: "『ハイレベルな男』の冬休みの過ごし方｜完全ガイド",
    channel: "ジョージ・メンズコーチ-"
  },
  {
    video_id: "7O0-kkBxhMo",
    title: "【頭のいい人が話す前に考えていること】知性と信頼をもたら・・・",
    channel: "ジョージ・メンズコーチ-"
  },
  # ABEMA
  {
    video_id: "BzWv-m8f9Qs",
    title: "【第1話フル】問題児ばかりの男たちをメンズコーチ ジョージが真・・・",
    channel: "ABEMA バラエティ【公式】"
  },
  # Stanford
  {
    video_id: "arj7oStGLkU",
    title: "Steve Jobs' 2005 Stanford Commencement Address",
    channel: "Stanford"
  },
  # その他
  {
    video_id: "cHJJQ0zNNOM",
    title: 'その"キツさ、辛さ、痛み"、結局100％割に合うんだって',
    channel: "ジョージ・メンズコーチ-"
  },
  {
    video_id: "JnMrFjpPWP4",
    title: "【完全密着】生産性を極めた人間の「究極の24時間」",
    channel: "マコなり社長"
  },
  {
    video_id: "Ks-_Mh1QhMc",
    title: "これが、生産性の鬼。",
    channel: "マコなり社長"
  },
]

# ===== 投稿作成 =====
puts "Creating posts..."

posts = []
youtube_videos.each_with_index do |video, index|
  # 各ユーザーにランダムに投稿を割り当て
  user = all_users[index % all_users.size]
  post = Post.create!(
    user: user,
    youtube_url: "https://www.youtube.com/watch?v=#{video[:video_id]}",
    youtube_video_id: video[:video_id],
    youtube_title: video[:title],
    youtube_channel_name: video[:channel]
  )
  posts << post
end

# ===== アクションプラン作成 =====
puts "Creating action plans..."

# 実際に使われそうなアクションプラン例
action_plan_templates = [
  # 朝の習慣系
  { content: "朝起きたら5分間瞑想する", deadline_offset: 3 },
  { content: "毎朝6時に起きる習慣をつける", deadline_offset: 7 },
  { content: "朝食前にコップ1杯の水を飲む", deadline_offset: 1 },
  # 学習系
  { content: "Progateで毎日30分プログラミング学習", deadline_offset: 14 },
  { content: "英語のPodcastを通勤中に聴く", deadline_offset: 7 },
  { content: "寝る前に15分読書する", deadline_offset: 5 },
  { content: "週末に本を1冊読み切る", deadline_offset: 10 },
  # 運動系
  { content: "週3回、20分の筋トレを行う", deadline_offset: 7 },
  { content: "毎日10000歩歩く", deadline_offset: 3 },
  { content: "ストレッチを毎晩10分行う", deadline_offset: 5 },
  # 生産性系
  { content: "スマホのスクリーンタイムを2時間以内にする", deadline_offset: 7 },
  { content: "タスクをToDoリストに書き出してから仕事を始める", deadline_offset: 1 },
  { content: "ポモドーロテクニックを1週間試す", deadline_offset: 7 },
  # 生活改善系
  { content: "週末に作り置きおかずを3品作る", deadline_offset: 5 },
  { content: "毎日23時までに寝る", deadline_offset: 7 },
  { content: "SNSを見る時間を1日30分に制限", deadline_offset: 3 },
  # コミュニケーション系
  { content: "1日1回、誰かに感謝を伝える", deadline_offset: 7 },
  { content: "週1回、友人と電話する時間を作る", deadline_offset: 14 },
  # お金系
  { content: "毎日の支出を記録する", deadline_offset: 30 },
  { content: "月に1万円を投資に回す", deadline_offset: 30 },
  { content: "固定費を見直して1つ削減する", deadline_offset: 14 },
]

# 各ユーザーにアクションプランを作成
all_users.each do |user|
  # ランダムに3〜8個のアクションプランを作成
  plan_count = rand(3..8)
  selected_plans = action_plan_templates.sample(plan_count)
  selected_posts = posts.sample(plan_count)

  selected_plans.each_with_index do |plan, i|
    post = selected_posts[i]

    # 50%の確率で達成済みにする
    is_achieved = rand < 0.5

    entry = PostEntry.new(
      post: post,
      user: user,
      content: plan[:content],
      deadline: Date.current + plan[:deadline_offset].days,
      achieved_at: is_achieved ? Time.current - rand(1..10).days : nil
    )
    entry.save!(validate: false)
  end
end

# ===== メインユーザーに追加のアクションプラン =====
puts "Creating main user's specific action plans..."

# 未達成のアクションプラン（様々な期限）
main_user_pending = [
  { content: "明日から毎朝5時起きを実践", deadline: Date.current + 1.day, post: posts[0] },
  { content: "1日1回、新しい英単語を10個覚える", deadline: Date.current + 3.days, post: posts[1] },
  { content: "週末までにKindle本を1冊読み終える", deadline: Date.current + 5.days, post: posts[2] },
  { content: "来週から毎日腕立て30回", deadline: Date.current + 7.days, post: posts[3] },
  { content: "今月中に副業のアイデアを3つ出す", deadline: Date.current + 14.days, post: posts[4] },
]

main_user_pending.each do |plan|
  entry = PostEntry.new(
    post: plan[:post],
    user: main_user,
    content: plan[:content],
    deadline: plan[:deadline],
    achieved_at: nil
  )
  entry.save!(validate: false)
end

# 達成済みのアクションプラン
main_user_achieved = [
  { content: "ああああああああああああああああ", deadline: Date.current - 3.days, post: posts[5] },
  { content: "あ", deadline: Date.current - 5.days, post: posts[9] },
  { content: "アクションプラン２", deadline: Date.current - 7.days, post: posts[9] },
]

main_user_achieved.each do |plan|
  entry = PostEntry.new(
    post: plan[:post],
    user: main_user,
    content: plan[:content],
    deadline: plan[:deadline],
    achieved_at: Time.current - rand(1..5).days
  )
  entry.save!(validate: false)
end

# ===== 応援（Cheer）を作成 =====
puts "Creating cheers..."

posts.first(10).each do |post|
  # 各投稿に0〜5個の応援をランダムに追加
  cheering_users = all_users.sample(rand(0..5))
  cheering_users.each do |user|
    Cheer.create!(user: user, post: post) rescue nil
  end
end

# ===== ユーザーの引用設定 =====
puts "Setting user favorite quotes..."

quotes = [
  { quote: "継続は力なり。毎日少しずつでも前に進もう。", video_index: 0 },
  { quote: "人生を変えるのは、大きな決断ではなく小さな習慣。", video_index: 1 },
  { quote: "失敗を恐れるな。挑戦しないことを恐れろ。", video_index: 3 },
  { quote: "今日という日は、残りの人生の最初の日。", video_index: 6 },
  { quote: "他人の目を気にするな。自分の人生を生きろ。", video_index: 2 },
]

all_users.first(5).each_with_index do |user, i|
  quote_data = quotes[i]
  if quote_data
    user.update!(
      favorite_quote: quote_data[:quote],
      favorite_quote_url: "https://www.youtube.com/watch?v=#{youtube_videos[quote_data[:video_index]][:video_id]}"
    )
  end
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
puts "  Action Plans (total): #{PostEntry.count}"
puts "  Action Plans (achieved): #{PostEntry.achieved.count}"
puts "  Action Plans (pending): #{PostEntry.not_achieved.count}"
puts "  Cheers: #{Cheer.count}"
puts ""
