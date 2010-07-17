User.blueprint do
  account_key           { ActiveSupport::SecureRandom.hex(16) }
  username              { "john-test-#{ActiveSupport::SecureRandom.hex(6)}" }
  name                  { "John Test #{ActiveSupport::SecureRandom.hex(6)}" }
  password              { "abcdefg" }
  password_confirmation { "abcdefg" }
  email                 { "#{ActiveSupport::SecureRandom.hex(6)}@example.com" }

  # Assume that the user was good and set their country even though it's optional
  country_id            { Country.us.id } # United States of America
  postal_code           { '94104' }
end