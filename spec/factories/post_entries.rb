# PostEntryファクトリー
# create(:post_entry), create(:post_entry, :achieved), create(:post_entry, :overdue)

FactoryBot.define do
  factory :post_entry do
    association :post
    association :user
    content { Faker::Lorem.sentence(word_count: 8) }
    deadline { Date.current + 7.days }

    trait :action do
      # entry_type: 0 がデフォルト
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
