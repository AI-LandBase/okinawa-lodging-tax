FactoryBot.define do
  factory :stay do
    check_in_date { Date.current }
    nights { 1 }
    guest_name { Faker::Name.name }
    num_guests { 2 }
    num_taxable_guests { 2 }
    num_exempt_guests { 0 }
    nightly_rate { 8_000 }
    status { "active" }
    association :created_by_user, factory: :user
    association :updated_by_user, factory: :user
  end
end
