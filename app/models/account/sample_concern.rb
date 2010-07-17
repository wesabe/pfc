class Account
  def self.create_sample(attrs={})
    Account.create(attrs.reverse_merge(
      :name => "Sample Account",
      :currency => 'USD',
      :account_type_id => AccountType::CHECKING,
      :balance => rand(2000) - 1000
    ))
  end
end
