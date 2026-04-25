unless Rails.env.production?
  Rails.application.config.secret_key_base = ENV.fetch("SECRET_KEY_BASE") {
    "dev-only-secret-key-base-for-sales-crm-do-not-use-in-production-" + "x" * 64
  }
end
