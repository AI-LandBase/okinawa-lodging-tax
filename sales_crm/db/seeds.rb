if Rails.env.development? && User.count.zero?
  User.create!(
    name: "Admin",
    email: "admin@example.com",
    password: "password123",
    password_confirmation: "password123",
    active: true
  )
  puts "Seed user created: admin@example.com / password123"
end
