InvestmentBalance.blueprint do
  upload          { Upload.make }
  account         { InvestmentAccount.make }
  avail_cash      { rand(1_000) }
  margin_balance  { rand(10_000) }
  short_balance   { rand(50) }
  buy_power       { rand(2_000) }
  date            { Time.now }
end