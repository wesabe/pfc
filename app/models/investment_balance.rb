class InvestmentBalance < ActiveRecord::Base
  belongs_to :account
  belongs_to :upload
  has_many :other_balances,
           :class_name => "InvestmentOtherBalance"

  # convenience method to return the balance currency, which is just the account's currency
  def currency
    account.currency
  end

  def available_cash
    if amount = read_attribute(:avail_cash)
      Money.new(amount, currency)
    end
  end

  def margin_balance
    if amount = read_attribute(:margin_balance)
      Money.new(amount, currency)
    end
  end

  def short_balance
    if amount = read_attribute(:short_balance)
      Money.new(amount, currency)
    end
  end

  def buy_power
    if amount = read_attribute(:buy_power)
      Money.new(amount, currency)
    end
  end

  # fake out balance to return the market value of the account, since that's what users would expect to see
  def balance
    account.market_value.amount
  end
end
