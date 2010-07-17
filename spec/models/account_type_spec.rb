require 'spec_helper'

describe AccountType do
  before do
    @account_type = AccountType::ACCOUNT_TYPES[AccountType::CHECKING]
  end

  it "should have a raw name" do
    @account_type.raw_name.should == "CHECKING"
  end

  it "should have a name" do
    @account_type.name == "Checking"
  end

  it "should have visibility" do
    @account_type.visible.should be_true
  end

  it "should have balance flag" do
    @account_type.should have_balance
  end

  it "should have fi flag" do
    @account_type.should have_fi
  end

  it "should have uploads flag" do
    @account_type.should have_uploads
  end

  it "should have an id" do
    @account_type.id.should == AccountType::CHECKING
  end

  it "should not have a nil string value" do
    AccountType.new(:name => nil).to_s.should == ''
  end
end


describe AccountType, "class finders" do
  it "should include find" do
    (0..9).each do |id|
      AccountType.find(id).should == AccountType::ACCOUNT_TYPES[id]
    end
  end

  it "should include find all" do
    AccountType.find(:all).should == AccountType::ACCOUNT_TYPES.values
  end

  it "should include visible names" do
    names = AccountType::ACCOUNT_TYPES.values.reject{|a| !a.visible }.map(&:name).sort
    AccountType.visible_names.should == names
  end

end


describe AccountType, "find by raw name" do
  it "should find checking" do
    checking = AccountType::ACCOUNT_TYPES[AccountType::CHECKING]
    ["Checking", "checking", "CHECKING"].each do |string|
      AccountType.find_by_raw_name(string).should == checking
    end
  end

  it "should find credit card" do
    creditcard = AccountType::ACCOUNT_TYPES[AccountType::CREDITCARD]
    ["credit card", "Credit  Card", "CREDIT   CARD", "2"].each do |string|
      AccountType.find_by_raw_name(string).should == creditcard
    end
  end
  it "should find credit line" do
    creditline = AccountType::ACCOUNT_TYPES[AccountType::CREDITLINE]
    ["credit line", "Credit  Line", "CREDIT   LINE"].each do |string|
      AccountType.find_by_raw_name(string).should == creditline
    end
  end
  it "should find money market" do
    moneymarket = AccountType::ACCOUNT_TYPES[AccountType::MONEYMRKT]
    ["money market", "Money  Market", "MONEY   MARKET", "money mrkt"].each do |string|
      AccountType.find_by_raw_name(string).should == moneymarket
    end
  end

  it "should find savings" do
    savings = AccountType::ACCOUNT_TYPES[AccountType::SAVINGS]
    ["savings", "Savings", "SAVINGS"].each do |string|
      AccountType.find_by_raw_name(string).should == savings
    end
  end

  it "should find brokerage" do
    brokerage = AccountType::ACCOUNT_TYPES[AccountType::BROKERAGE]
    ["brokerage", "Brokerage", "BROKERAGE"].each do |string|
      AccountType.find_by_raw_name(string).should == brokerage
    end
  end

  it "should find cash" do
    cash = AccountType::ACCOUNT_TYPES[AccountType::CASH]
    ["cash", "Cash", "CASH"].each do |string|
      AccountType.find_by_raw_name(string).should == cash
    end
  end

  it "should find unknown" do
    unknown = AccountType::ACCOUNT_TYPES[AccountType::UNKNOWN]
    ["unknown", "something else", "!@#7892@#&^"].each do |string|
      AccountType.find_by_raw_name(string).should == unknown
    end
  end

end
