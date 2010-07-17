require 'spec_helper'

describe Currency do
  it "should default to USD" do
    [nil, ''].each do |blank|
      Currency.new(blank).name.should == 'USD'
    end
  end

  it "should set derived data from the name" do
    currency = Currency.new('USD')
    currency.should be_an_instance_of(Currency)
    currency.name.should == 'USD'
    currency.unit.should == '$'
    currency.separator.should == '.'
    currency.delimiter.should == ','
  end

  it "should raise unknown currency exception on an unknown name" do
    lambda { Currency.new('XXX') }.should raise_error(Currency::UnknownCurrencyException)
  end

  it "should allow constructing with a Currency instance" do
    Currency.new(Currency.new('USD')).should == Currency.new('USD')
  end
end

describe Currency, 'comparison' do
  it "should be equivalent to another object of the same currency" do
    Currency.list.each do |name|
      Currency.new(name).should == Currency.new(name)
    end
  end

  it "should not be equivalent to another object of a different currency" do
    Currency.new('USD').should_not == Currency.new('GBP')
  end

  it "should equal a string that matches the currency name" do
    Currency.new('USD').should == "USD"
  end

  it "should not equal something that is not a Currency or a string of the same name" do
    [nil, 45].each do |other|
      Currency.new('USD').should_not == other
    end
  end
end

describe Currency, 'normalizing' do
  it "should strip off all non-digit characters" do
    Currency.normalize('$45.00').should == '45.00'
    Currency.normalize('€45.00').should == '45.00'
    Currency.normalize('20$').should == '20.00'
    Currency.normalize('20R').should == '20.00'
  end

  it "should interpret a single period as a decimal delimiter" do
    Currency.normalize('2.890').should == '2.89'
  end

  it "should use whichever delimiter has two trailing numbers as the decimal delimiter" do
    Currency.normalize('3.563,98').should == '3563.98'
    Currency.normalize('2,452.81').should == '2452.81'
  end

  it "should remove thousands separators on numbers without decimal places" do
    Currency.normalize('1,000').should == '1000.00'
  end

  it "should work in the crazy other parts of the world" do
    Currency.normalize('12,34,567.89').should == '1234567.89' # Indian
    Currency.normalize('1.234.567,89').should == '1234567.89' # German
    Currency.normalize("1'234'567,89").should == '1234567.89' # Swiss
    Currency.normalize('1 234 567,89').should == '1234567.89' # French
    Currency.normalize('12.345.67').should    == '12345.67'   # WTF French
  end

  it "should preserve negative signs" do
    Currency.normalize('-$2000.00').should  == '-2000.00'
    Currency.normalize('$-2000.00').should  == '-2000.00'
    Currency.normalize('-2,000.00').should  == '-2000.00'
    Currency.normalize('-20R').should       == '-20.00'
    Currency.normalize('-2,000.00R').should == '-2000.00'
    Currency.normalize('-2,000R').should    == '-2000.00'
    Currency.normalize('-7.9').should       == '-7.90'
  end

  it "should round to two decimal places" do
    Currency.normalize('-14.399999999999999').should == '-14.40'
    Currency.normalize('3.211111111111').should == '3.21'
  end

  it "should be okay with oddly placed separators" do
    Currency.normalize('R2 000 000,00').should  == '2000000.00'
    Currency.normalize('1,23.45').should        == '123.45'
  end
end
