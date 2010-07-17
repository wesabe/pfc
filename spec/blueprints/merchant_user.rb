MerchantUser.blueprint do
  sign              { -1 }
  autotags_disabled { false }
  merchant          { Merchant.make }
  user              { User.make }
end