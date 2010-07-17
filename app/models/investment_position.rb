class InvestmentPosition < ActiveRecord::Base
  belongs_to :account
  belongs_to :upload
  belongs_to :investment_security

  def currency
    account.currency
  end

  def unit_price
    Money.new(read_attribute(:unit_price), currency)
  end

  def total
    unit_price * units
  end
end
