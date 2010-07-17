FinancialInst.blueprint do
  name            { "#{Faker::Name.name} Bank" }
  country         { Country.us }
  bad_balance     { false }
  homepage_url    { "http://www.example.com/" }
  login_url       { "http://www.example.com/login" }
  connection_type { "Automatic" }
end