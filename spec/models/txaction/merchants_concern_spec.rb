require 'spec_helper'

describe Txaction, "saving a transaction" do
  it_should_behave_like "it has a logged-in user"

  def amts_count(merchant, user)
    AccountMerchantTagStat.count(:conditions => {:merchant_id => merchant.id, :account_key => user.account_key})
  end

  def merchant_user_count(merchant, user)
    MerchantUser.count(:conditions => {:merchant_id => merchant.id, :user_id => user.id})
  end

  before do
    @account = Account.make(:user => current_user)
  end

  describe "with a new merchant" do
    before do
      @new_merchant = Merchant.make
    end

    describe "that has no existing merchant or tags" do
      before do
        @txaction = Txaction.make(:account => @account)
      end

      it "should not update the AMTS table" do
        amts_count(@new_merchant, current_user).should == 0
      end

      it "should update the merchant_users table" do
        lambda {
          @txaction.merchant = @new_merchant
          @txaction.save
        }.should change {
          merchant_user_count(@new_merchant, current_user)
        }.from(0).to(1)
      end
    end

    describe "that has a existing merchant" do
      before do
        @merchant = Merchant.make
        @txaction = Txaction.make(:account => @account, :merchant => @merchant)
        @txaction.tag_with("foo bar")
        @other_txaction = Txaction.make(:account => @account, :merchant => @merchant)
        @other_txaction.tag_with("bar baz")
      end


      it "should update the AMTS table" do
        amts_count(@merchant, current_user).should == 3
        @txaction.merchant = @new_merchant
        @txaction.save!
        amts_count(@merchant, current_user).should == 2
        amts_count(@new_merchant, current_user).should == 2
        @other_txaction.merchant = @new_merchant
        @other_txaction.save!
        amts_count(@merchant, current_user).should == 0
        amts_count(@new_merchant, current_user).should == 3
      end

      it "should update the merchants_users table" do
        merchant_user_count(@merchant, current_user).should == 1
        @txaction.merchant = @new_merchant
        @txaction.save!
        merchant_user_count(@merchant, current_user).should == 1
        merchant_user_count(@new_merchant, current_user).should == 1
        @other_txaction.merchant = @new_merchant
        @other_txaction.save!
        merchant_user_count(@merchant, current_user).should == 0
        merchant_user_count(@new_merchant, current_user).should == 1
      end
    end
  end
end