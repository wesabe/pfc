require 'spec_helper'

describe User, "merchants method" do
  it_should_behave_like "it has a logged-in user"

  before do
    @account = Account.make(:user => @current_user)
    @merchants = [
      Merchant.make,
      Merchant.make
    ]
    @txactions = [
      Txaction.make(:account => @account, :merchant => @merchants[0]),
      Txaction.make(:account => @account, :merchant => @merchants[0]),
      Txaction.make(:account => @account, :merchant => @merchants[1])
    ]
  end

  it "should return a list of unique merchants" do
    @current_user.merchants.map(&:id).should == @merchants.map(&:id)
  end

  it "should include a usage count for each" do
    user_merchants = @current_user.merchants
    user_merchants.find {|m| m.id == @merchants[0].id}.count.to_i.should == 2
    user_merchants.find {|m| m.id == @merchants[1].id}.count.to_i.should == 1
  end

  it "should return an empty array if the user has no accounts" do
    @account.destroy
    @current_user.merchants.should == []
  end
end