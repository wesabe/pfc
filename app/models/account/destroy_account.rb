class Account::DestroyAccount
  @queue = :normal

  def self.perform(id)
    account = Account.find_by_id(id)
    return if account.nil?

    User.with_current_user(account.user) do
      account.destroy
    end
  end
end
