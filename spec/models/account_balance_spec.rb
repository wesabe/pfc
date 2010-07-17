require 'spec_helper'

describe AccountBalance do
  before do
    @account_balance = AccountBalance.make
  end

  it "should belong to an account" do
    @account_balance.account.should be_an(Account)
  end

  it "should belong to an upload" do
    @account_balance.upload.should be_an(Upload)
  end

  it "should not be valid without a balance" do
    @account_balance.balance = nil
    @account_balance.should_not be_valid
    @account_balance.balance = 'not a number'
    @account_balance.should_not be_valid
    @account_balance.balance = 100
    @account_balance.should be_valid
  end

  it "should have a Money balance" do
    @account_balance.balance = 100
    @account_balance.account = Account.make(:currency => 'GBP')
    @account_balance.money_balance.should == Money.new(100, 'GBP')
  end
end
