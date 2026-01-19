# spec/factories/post_entries.rb
FactoryBot.define do
  factory :post_entry do
    association :post
    association :user
    content { Faker::Lorem.sentence(word_count: 8) }
    deadline { Date.current + 7.days }

    trait :action do
      # Default is already action type (entry_type: 0)
    end

    trait :achieved do
      achieved_at { Time.current }
    end

    trait :without_deadline do
      deadline { nil }
    end

    trait :overdue do
      deadline { Date.current - 3.days }
    end
  end
end
