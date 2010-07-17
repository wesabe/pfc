InvestmentAccount.blueprint do
  user            { User.make }
  name            { "Test Account" }
  account_type_id { AccountType::BROKERAGE }
  currency        { "USD" }
  guid            { ActiveSupport::SecureRandom.hex(64) }
  last_balance    { InvestmentBalance.new(:created_at => Time.now) }
  account_number  { ActiveSupport::SecureRandom.hex(4) }
  financial_inst  { FinancialInst.make }
end