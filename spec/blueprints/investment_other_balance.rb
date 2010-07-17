InvestmentOtherBalance.blueprint do
  name         { "Total Account Value" }
  description  { "Total Account Value" }
  type         { "DOLLAR" }
  value        { rand(10_000) }
  date         { Time.now }
end