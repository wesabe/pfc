AccountCred.blueprint do
  financial_inst { FinancialInst.make }
  account_key    { 'abc123' }
  cred_key       { 'abc123' }
  cred_guid      { ActiveSupport::SecureRandom.hex(16) }
end