FactoryBot.define do
  factory :inquiry do
    facility_name { Faker::Company.name }
    contact_name { Faker::Name.name }
    email { Faker::Internet.email }
    phone { "098-#{rand(100..999)}-#{rand(1000..9999)}" }
    facility_type { Inquiry::FACILITY_TYPES.sample }
    has_pc { Inquiry::HAS_PC_OPTIONS.sample }
    message { Faker::Lorem.paragraph }
  end
end
