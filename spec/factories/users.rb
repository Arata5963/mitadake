# Userファクトリー
# create(:user), create(:user, :from_google), create(:user, :with_avatar)

FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    email { Faker::Internet.unique.email }
    password { "password123" }

    trait :from_google do
      provider { "google_oauth2" }
      uid { Faker::Number.number(digits: 20).to_s }
      password { nil }
    end

    trait :with_avatar do
      avatar { Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/sample_avatar.jpg"), "image/jpeg") }
    end
  end
end
