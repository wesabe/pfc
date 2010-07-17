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

describe Country, "selecting ids and names" do
  it "should select the ids and names of all countries, sorted by names" do
    connection = mock(:connection)
    Country.should_receive(:connection).and_return(connection)
    connection.should_receive(:select_rows).with("SELECT name, id FROM countries ORDER BY name ASC").and_return([["Oceania", "1"], ["Eurasia", "2"], ["Eastasia", "3"]])
    Country.ids_and_names.should == [["Oceania", 1], ["Eurasia", 2], ["Eastasia", 3]]
  end
end