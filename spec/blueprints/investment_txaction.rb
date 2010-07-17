InvestmentTxaction.blueprint do
  account              { InvestmentAccount.make }
  upload               { Upload.make }
  txid                 { UID.generate }
  memo                 { UID.generate }
  original_trade_date  { Time.now }
  original_settle_date { Time.now}
  trade_date           { Time.now }
  settle_date          { Time.now}
  investment_security  { InvestmentSecurity.make }
  units                { rand(20) }
  unit_price           { rand(300) }
  commission           { rand(5) }
  withholding          { rand(60) }
  fees                 { 8 + rand(4) }
  total                { rand(1000) }
  note                 { UID.generate }
  income_type          { 'DIV' }
  buy_sell_type        { InvestmentTxaction::TYPES.keys.random }
  sub_account_type     { 'CASH' }
  sub_account_fund     { UID.generate }
end