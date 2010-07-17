InvestmentSecurity.blueprint do
  unique_id      { ActiveSupport::SecureRandom.hex(16) }
  unique_id_type { "CUSIP" }
end