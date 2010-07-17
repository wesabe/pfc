Attachment.blueprint do
  filename      { ActiveSupport::SecureRandom.hex(6) }
  guid          { ActiveSupport::SecureRandom.hex(32) }
  description   { Faker::Lorem.sentence }
  content_type  { "image/png" }
  size          { 123456 }
end