require 'spec_helper'

describe Country do
  before do
    @country_with_valid_currency = Country.new(:currency => 'JPY')
    @country_with_invalid_currency = Country.new(:currency => '***')
  end

  it "should return a Currency named for a valid currency name is used" do
    @country_with_valid_currency.currency.name.should == 'JPY'
  end

  it "should return USD Currency when an invalid currency name is used" do
    @country_with_invalid_currency.currency.name.should == 'USD'
  end
end
