module CurrencyHelper
  COMMON_CURRENCIES = %w{USD AUD CAD EUR GBP NZD} unless defined?(COMMON_CURRENCIES)
  def currency_full_options_for_select
    data = Currency.data
    all_options = data.keys.sort.map {|cur| ["#{cur} - #{data[cur][4]} (#{data[cur][0]})",cur]}
    # put most common currencies first
    COMMON_CURRENCIES.map {|cur| ["#{cur} - #{data[cur][4]} (#{data[cur][0]})", cur]} + ['---'] + all_options
  end

  def currency_short_options_for_select
    data = Currency.data
    all_options = data.keys.sort.map {|cur| ["#{cur} (#{data[cur][0]})",cur]}
    # put most common currencies first
    COMMON_CURRENCIES.map {|cur| ["#{cur} (#{data[cur][0]})", cur]} + ['---'] + all_options
  end
end