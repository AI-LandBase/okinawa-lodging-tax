# CORS configuration
# Adjust origins for your production environment

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins "http://localhost:3000"

    resource "*",
      headers: :any,
      methods: [ :get, :post, :put, :patch, :delete, :options, :head ]
  end

  allow do
    origins "https://lodging-tax.ai-landbase.jp"

    resource "/api/inquiries",
      headers: :any,
      methods: [ :post, :options ]
  end
end
