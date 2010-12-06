Rspec.configure do |config|
  WebMock.disable_net_connect!

  def clear_currency_exchange_rates
    CurrencyExchangeRate.delete_all
    Rails.cache.clear
  end
end
