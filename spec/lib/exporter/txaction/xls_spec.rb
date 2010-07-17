require 'spec_helper'


describe Exporter::Txaction::Csv do
  before do
    @user = User.make
    data = ActiveSupport::JSON.decode(File.read(File.dirname(__FILE__) + '/../../../fixtures/transactions.json'))
    @exporter = Exporter::Txaction::Xls.new(@user, data)
    @accounts = [
      Account.make(:user => @user, :name => "My Checking", :account_type_id => AccountType::CHECKING),
      Account.make(:user => @user, :name => "My Savings", :account_type_id => AccountType::SAVINGS)]
  end

  it "should convert an array of transactions into TSV" do
    csv_lines = @exporter.convert.split("\n")
    csv_lines[0].should == "Account Id\tAccount Name\tFinancial Institution\tAccount Type\tCurrency\tTransaction Date\tCheck Number\tAmount\tMerchant\tBank Name\tNote\tTags"
    csv_lines[1].should == "1\tMy Checking\t#{@accounts[0].financial_inst.name}\tChecking\tUSD\t2009-10-23\t\t-7.95\tBaladie\tBALADIE GOURMET CAFE       SAN F\tAwesome shawarma!\trestaurant, lunch"
    csv_lines[2].should == "1\tMy Checking\t#{@accounts[0].financial_inst.name}\tChecking\tUSD\t2009-10-22\t\t-122.00\tATM Withdrawal\t465 CALIFORNIA ST          SAN F\t\"\"\tcash:120.0, fee:2.0"
    csv_lines[3].should == "1\tMy Checking\t#{@accounts[0].financial_inst.name}\tChecking\tUSD\t2009-10-21\t1099\t-175.94\t\tCHECK # 0000001099\t\t\"\""
    csv_lines[4].should == "2\tMy Savings\t#{@accounts[1].financial_inst.name}\tSavings\tUSD\t2009-10-15\t\t5.17\tInterest Paid\tINTEREST PAID\t\tinterest"
  end
end