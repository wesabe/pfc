Txaction.blueprint do
  account        { Account.make }
  raw_name       { "PUKITYPUKE" }
  filtered_name  { "PUKITYPUKE" }
  cleaned_name   { "PUKITYPUKE" }
  txid           { "omgtxid-#{ActiveSupport::SecureRandom.hex(6)}" }
  wesabe_txid    { "wesabetxid-#{ActiveSupport::SecureRandom.hex(6)}" }
  amount         { -40.00 }
  date_posted    { Time.now }
  txaction_type  { TxactionType.find_or_new_by_name("DEBIT") }
end

Txaction.blueprint(:disabled) do
  status { Txaction::Status::DISABLED }
end

Txaction.blueprint(:deleted) do
  status { Txaction::Status::DELETED }
end