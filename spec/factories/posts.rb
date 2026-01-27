# Postファクトリー
# create(:post), create(:post, :with_user), create(:post, :with_entries)

FactoryBot.define do
  factory :post do
    action_plan { Faker::Lorem.sentence(word_count: 10) }
    youtube_url { "https://www.youtube.com/watch?v=#{Faker::Alphanumeric.alphanumeric(number: 11)}" }
    youtube_title { Faker::Lorem.sentence(word_count: 5) }
    youtube_channel_name { Faker::Name.name }

    trait :with_user do
      association :user
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
