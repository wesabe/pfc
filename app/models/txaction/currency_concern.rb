# currency concern for Txaction
class Txaction
  attr_accessor :currency
  before_save :set_usd_amount

  # convenience method to return the currency of this transaction
  def currency
    read_attribute('currency') || (@currency ||= account && account.currency)
  end

  # convert amount to USD equivalent; called from before_save
  def set_usd_amount
    self.usd_amount = CurrencyExchangeRate.convert_to_usd(amount, currency, date_posted)
  end

  # return the total of a list of transactions, converting to the target currency, optionally filtering by the given tag
  def self.sum_in_target_currency(txactions, target_currency, tag = nil)
    txactions.inject(0) do |sum, tx|
      if (tx.account.currency == target_currency)
        sum + tx.amount(:tag => tag)
      else
        sum + CurrencyExchangeRate.convert_from_usd(tx.usd_amount(:tag => tag), target_currency)
      end
    end
  end

end
