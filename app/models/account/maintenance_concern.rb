# maintenance concern for tasks such as finding and removing duplicate transactions
class Account
  # find duplicate transactions in this account, returning the oldest txaction of any set of duplicates
  # I'm defining this as a class method so the tasks in accounts.rake don't need to load an entire Account object
  def self.find_duplicate_txactions(account_id)
    Txaction.find_by_sql([%{
       select t1.*, min(t1.created_at) as oldest
       from txactions t1 use index(account_id), txactions t2 use index(account_id)
       where t1.account_id = ? and t2.account_id = t1.account_id
       and t1.status = ? and t2.status = t1.status
       and t1.id != t2.id
       and t1.upload_id != t2.upload_id
       and t1.txid = t2.txid
       and t1.txid IS NOT NULL
       and t1.txid != ''
       and t1.raw_name = t2.raw_name
       and t1.memo = t2.memo
       and t1.date_posted = t2.date_posted
       and t1.amount = t2.amount
       group by txid
       having t1.created_at = oldest}, account_id, Constants::Status::ACTIVE])
  end

  def find_duplicate_txactions
    self.class.find_duplicate_txactions(id)
  end
end
