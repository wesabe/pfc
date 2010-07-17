AccountBalance.blueprint do
  account      { Account.make }
  upload       { Upload.make }
  balance      { 1234.56 }
  balance_date { Time.now }
  status       { Constants::Status::ACTIVE }
end