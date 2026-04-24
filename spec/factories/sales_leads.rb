FactoryBot.define do
  factory :sales_lead do
    facility_name { Faker::Company.name }
    region { SalesLead::REGIONS.sample }
    area { "那覇市" }
    phone { "098-#{rand(100..999)}-#{rand(1000..9999)}" }
    sales_status { "未着手" }
  end
end
