require "square"

SQUARE_CLIENT = if ENV["SQUARE_ACCESS_TOKEN"].present?
  Square::Client.new(
    token: ENV.fetch("SQUARE_ACCESS_TOKEN"),
    base_url: ENV.fetch("SQUARE_ENVIRONMENT", "sandbox") == "production" ? Square::Environment::PRODUCTION : Square::Environment::SANDBOX
  )
end

SQUARE_LOCATION_ID = ENV["SQUARE_LOCATION_ID"]
