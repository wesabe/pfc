class Account::DestroyAccount
  @queue = :normal

  def self.perform(id)
    account = Account.find_by_id(id)
    account.destroy if account
  end
end