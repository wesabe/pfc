require 'spec_helper'


describe Exporter::Txaction::Csv do
  before do
    @user = User.make
    @data = ActiveSupport::JSON.decode(File.read(File.dirname(__FILE__) + '/../../../fixtures/transactions.json'))
    @exporter = Exporter::Txaction::Csv.new(@user, @data)
    @accounts = [
      Account.make(:checking, :user => @user, :name => "My Checking"),
      Account.make(:savings, user => @user, :name => "My Savings")]
  end

  it "should convert an array of tag hashes to a comma-separated string" do
    tag_array = [
      {"name" => "foo"},
      {"name" => "bar", "amount" => {"display" => "-$12.34", "value" => "-12.34"}}]
    @exporter.convert_tags(tag_array).should == "foo, bar:12.34"
  end

  it "should convert an array of transactions into CSV" do
    csv_lines = @exporter.convert.split("\n")
    csv_lines[0].should == "Account Id,Account Name,Financial Institution,Account Type,Currency,Transaction Date,Check Number,Amount,Merchant,Bank Name,Note,Tags"
    csv_lines[1].should == "1,My Checking,#{@accounts[0].financial_inst.name},Checking,USD,2009-10-23,,-7.95,Baladie,BALADIE GOURMET CAFE       SAN F,Awesome shawarma!,\"restaurant, lunch\""
    csv_lines[2].should == "1,My Checking,#{@accounts[0].financial_inst.name},Checking,USD,2009-10-22,,-122.00,ATM Withdrawal,465 CALIFORNIA ST          SAN F,\"\",\"cash:120.0, fee:2.0\""
    csv_lines[3].should == "1,My Checking,#{@accounts[0].financial_inst.name},Checking,USD,2009-10-21,1099,-175.94,,CHECK # 0000001099,,\"\""
    csv_lines[4].should == "2,My Savings,#{@accounts[1].financial_inst.name},Savings,USD,2009-10-15,,5.17,Interest Paid,INTEREST PAID,,interest"
  end

  describe "with a tag" do
    it "should scope the amounts to the tag" do
      # this test isn't quite realistic, because given the tag "fee", only the second transaction in this file would be returned
      # but it still tests what we need it to test
      @exporter = Exporter::Txaction::Csv.new(@user, @data, :tag => "fee")
      csv_lines = @exporter.convert.split("\n")
      csv_lines[0].should == "Account Id,Account Name,Financial Institution,Account Type,Currency,Transaction Date,Check Number,Amount,Merchant,Bank Name,Note,Tags"
      csv_lines[1].should == "1,My Checking,#{@accounts[0].financial_inst.name},Checking,USD,2009-10-23,,-7.95,Baladie,BALADIE GOURMET CAFE       SAN F,Awesome shawarma!,\"restaurant, lunch\""
      csv_lines[2].should == "1,My Checking,#{@accounts[0].financial_inst.name},Checking,USD,2009-10-22,,-2.00,ATM Withdrawal,465 CALIFORNIA ST          SAN F,\"\",\"cash:120.0, fee:2.0\""
      csv_lines[3].should == "1,My Checking,#{@accounts[0].financial_inst.name},Checking,USD,2009-10-21,1099,-175.94,,CHECK # 0000001099,,\"\""
      csv_lines[4].should == "2,My Savings,#{@accounts[1].financial_inst.name},Savings,USD,2009-10-15,,5.17,Interest Paid,INTEREST PAID,,interest"
    end
  end

end