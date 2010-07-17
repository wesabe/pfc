require 'spec_helper'

describe "CurrencyExchangeRate: Finding an exchange rate" do
  it "should convert weekend dates to the previous Friday" do
    cxr = CurrencyExchangeRate.find_rate('EUR', '2007-04-14')
    cxr.should_not be(nil)
    cxr.date.to_s.should eql('2007-04-13')
    cxr = CurrencyExchangeRate.find_rate('EUR', '2007-04-15')
    cxr.should_not be(nil)
    cxr.date.to_s.should eql('2007-04-13')
  end

  it "should convert old Euro code to new one" do
    cxr = CurrencyExchangeRate.find_rate('XEU', '2007-04-15')
    cxr.should_not be(nil)
    cxr.currency.should eql('EUR')
    cxr.date.to_s.should eql('2007-04-13')
  end

  it "should convert Euros to USD" do
    pending do
      CurrencyExchangeRate.convert_to_usd(10, 'EUR', currency_exchange_rates(:euro_on_a_friday).date).should be_close(13.518, 0.001)
    end
  end

  it "should convert USD to Euros" do
    pending do
      CurrencyExchangeRate.convert_from_usd(13.518, 'EUR', currency_exchange_rates(:euro_on_a_friday).date).should be_close(10.0, 0.001)
    end
  end

  it "should short circuit convertion between currencies if they match" do
    pending do
      date = currency_exchange_rates(:euro_on_a_friday).date
      eur  = 'EUR'
      eurc = Currency.new(eur)
      CurrencyExchangeRate.should_receive(:convert_to_usd).exactly(0).times
      CurrencyExchangeRate.convert(10, eur, eur, date).should eql(10.0)
      CurrencyExchangeRate.convert(10, eur, eurc, date).should eql(10.0)
      CurrencyExchangeRate.convert(10, eurc, eur, date).should eql(10.0)
      CurrencyExchangeRate.convert(10, eurc, eurc, date).should eql(10.0)
    end
  end

  it "should convert zero Euros to zero USD" do
    pending do
      CurrencyExchangeRate.convert_to_usd(0, 'EUR', currency_exchange_rates(:euro_on_a_friday).date).should eql(0.0)
    end
  end

  it "should convert USD to USD" do
    CurrencyExchangeRate.convert_to_usd(42.0, 'USD').should == 42.0.to_d
  end

  it "should return zero for an unknown currency" do
    CurrencyExchangeRate.convert_to_usd(42.0, 'XXX').should eql(0.0)
  end
end

describe "CurrencyExchangeRate: utility methods" do
  before do
    # force a cache miss to avoid caching issues
    Rails.cache.clear
  end

  it "returns true for supported currency" do
    CurrencyExchangeRate.make(:currency => 'EUR')
    CurrencyExchangeRate.should be_supported('EUR')
  end

  it "returns false for unsupported currency" do
    CurrencyExchangeRate.should_not be_supported('XXX')
  end
end
