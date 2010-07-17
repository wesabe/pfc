InvestmentPosition.blueprint do
  account                {  InvestmentAccount.make }
  upload                 {  Upload.make }
  investment_security    {  InvestmentSecurity.make }
  sub_account_type       {  'CASH' }
  position_type          {  'LONG' }
  units                  {  rand(100) }
  unit_price             {  rand(300) }
  market_value           {  rand(10_000) }
  price_date             {  Time.now }
  memo                   {  UID.generate }
  reinvest_dividends     {  true }
  reinvest_capital_gains {  true }
end