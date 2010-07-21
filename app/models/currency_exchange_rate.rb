class CurrencyExchangeRate < ActiveRecord::Base
  def self.supported?(currency)
    find_rate(currency).rate != 0
  end

  # return the exchange rate for the given currency closest to the given date
  def self.find_rate(currency, date = Date.today)
    currency = currency.name if currency.is_a?(Currency)

    # return identity rate for USD
    return CurrencyExchangeRate.new(:currency => 'USD', :date => date, :rate => 1) if currency == 'USD'

    if date.is_a?(Time)
      date = date.to_date
    elsif date.is_a?(String)
      date = Date.parse(date)
    end

    # convert old currency codes to their new code
    case currency
    when 'XEU' then currency = 'EUR' # Euro
    when 'RUR' then currency = 'RUB' # Ruble
    end

    # if date falls on a weekend, convert to friday
    case date.wday
    when 6 then date -= 1
    when 0 then date -= 2
    end

    rate = Rails.cache.fetch("CXR-#{currency}-#{date}") do
      # try to get exact match; if that fails, do a more expensive query to get the closest date for which we have a rate
      cxr = where(:currency => currency, :date => date).first || begin
        where(:currency => currency).map {|rate| [(rate.date - date).abs, rate]}.min.try(:at, 1)
      end
      cxr ? cxr.rate : 0
    end

    CurrencyExchangeRate.new(:currency => currency, :date => date, :rate => rate)
  end

  # convert the given amount in the specified currency to USD
  # if a date is provided, use the rate on or near that date, otherwise use yesterday (since we
  # probably don't have today's rates yet)
  def self.convert_to_usd(amount, currency, date = Date.today - 1)
    rate = find_rate(currency, date).rate
    rate > 0 ? amount.to_d / rate : 0.0.to_d
  end

  # convert the given amount from USD to the specified currency
  # if a date is provided, use the rate on or near that date, otherwise use yesterday (since we
  # probably don't have today's rates yet)
  def self.convert_from_usd(amount, currency, date = Date.today - 1)
    amount.to_d * find_rate(currency, date).rate
  end

  # convert between any two currencies
  def self.convert(amount, source_currency, target_currency, date = Date.today - 1)
    source_currency, target_currency = Currency.new(source_currency), Currency.new(target_currency)
    if source_currency == target_currency
      amount.to_d
    else
      convert_from_usd(convert_to_usd(amount, source_currency, date), target_currency, date)
    end
  end
end
