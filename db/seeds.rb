if Rails.env.production? && User.count.zero?
  User.find_or_create_by!(email: ENV.fetch("INITIAL_ADMIN_EMAIL")) do |user|
    user.name = ENV.fetch("INITIAL_ADMIN_NAME")
    user.password = ENV.fetch("INITIAL_ADMIN_PASSWORD")
  end
  puts "Initial admin user created: #{ENV.fetch('INITIAL_ADMIN_EMAIL')}"
end
