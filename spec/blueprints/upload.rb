Upload.blueprint do
  status   { Constants::Status::ACTIVE }
  filepath { "tmp/#{ActiveSupport::SecureRandom.hex(8)}.dat" }
end