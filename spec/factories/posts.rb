# spec/factories/posts.rb
FactoryBot.define do
  factory :post do
    # 必須項目
    action_plan { Faker::Lorem.sentence(word_count: 10) }
    youtube_url { "https://www.youtube.com/watch?v=#{Faker::Alphanumeric.alphanumeric(number: 11)}" }
    youtube_title { Faker::Lorem.sentence(word_count: 5) }
    youtube_channel_name { Faker::Name.name }

    # ユーザー付き（任意）
    trait :with_user do
      association :user
    end

    # 関連データ付き
    trait :with_achievements do
      transient do
        achievements_count { 3 }
        achievement_user { nil }
      end

      after(:create) do |post, evaluator|
        user = evaluator.achievement_user || create(:user)
        create_list(:achievement, evaluator.achievements_count, post: post, user: user)
      end
    end

    trait :with_entries do
      transient do
        entry_user { nil }
      end

      after(:create) do |post, evaluator|
        user = evaluator.entry_user || create(:user)
        create(:post_entry, :action, post: post, user: user)
      end
    end
  end
end
