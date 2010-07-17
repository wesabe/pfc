AccountMerchantTagStat.blueprint do
  account_key { User.make.account_key }
  merchant    { Merchant.make }
  sign        { -1 }
  name        { 'food' }
  tag         { Tag.find_or_create_by_name('food') }
end