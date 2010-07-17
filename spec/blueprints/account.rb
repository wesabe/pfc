Account.blueprint do
  user            { User.make }
  name            { "Test Account" }
  account_type_id { AccountType::CHECKING }
  currency        { "USD" }
  guid            { ActiveSupport::SecureRandom.hex(64) }
  last_balance    { AccountBalance.new(:created_at => Time.now) }
  account_number  { ActiveSupport::SecureRandom.hex(4) }

  # FinincialInst is not required, but present on all non-cash accounts
  financial_inst  { FinancialInst.make }
end

## Account types

Account.blueprint(:cash) do
  account_type_id { AccountType::CASH }
  financial_inst  { nil }
end

Account.blueprint(:manual) do
  account_type_id { AccountType::MANUAL }
  financial_inst  { nil }
end

Account.blueprint(:checking) do
  account_type_id { AccountType::CHECKING }
  financial_inst  { nil }
end

Account.blueprint(:savings) do
  account_type_id { AccountType::SAVINGS }
  financial_inst  { nil }
end

Account.blueprint(:credit) do
  account_type_id { AccountType::CREDITCARD }
  financial_inst  { nil }
end

## Account statuses

Account.blueprint(:disabled) do
  status { Constants::Status::DISABLED }
end

Account.blueprint(:archived) do
  status { Constants::Status::ARCHIVED }
end