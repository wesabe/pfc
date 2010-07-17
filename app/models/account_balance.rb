class AccountBalance < ActiveRecord::Base
  belongs_to :account
  belongs_to :upload

  validates_numericality_of :balance
  validates_presence_of :account

  def money_balance
    Money.new(balance, account.currency)
  end
end
