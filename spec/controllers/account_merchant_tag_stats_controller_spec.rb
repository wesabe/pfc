require 'spec_helper'

describe AccountMerchantTagStatsController do
  describe "handling GET /account_merchant_tag_stats/<id>?edit" do
    it_should_behave_like "it has a logged-in user"

    before do
      @merchant = Merchant.make
    end

    it "finds the right merchant" do
      get :edit, :id => @merchant.to_param
      assigns(:merchant).should == @merchant
    end

    it "defaults to negative sign" do
      get :edit, :id => @merchant.to_param
      assigns(:sign).should == -1
    end
  end

  describe "handling PUT /account_merchant_tag_stats/:id" do
    it_should_behave_like "it has a logged-in user"

    before do
      @merchant = Merchant.make
      @sign = -1
      @old_tags = "foo bar"
      @autotags = "bar baz"
    end

    it "should force on new tags" do
      AccountMerchantTagStat.should_receive(:force_on).with(@current_user, @merchant, -1, ["bar", "baz"])
      put :update, :id => @merchant.id, :sign => @sign, :autotags => @autotags, :old_tags => @old_tags
    end

    it "should force off old tags" do
      AccountMerchantTagStat.should_receive(:force_off).with(@current_user, @merchant, -1, ["foo"])
      put :update, :id => @merchant.id, :sign => @sign, :autotags => @autotags, :old_tags => @old_tags
    end

    it "should update other transactions if update_all is checked" do
      Txaction.should_receive(:add_tags_for_merchant).with(@current_user, @merchant, -1, ["bar", "baz"])
      Txaction.should_receive(:remove_tags_for_merchant).with(@current_user, @merchant, -1, ["foo"])
      put :update, :id => @merchant.id, :sign => @sign, :autotags => @autotags, :old_tags => @old_tags, :update_all => 1
    end

    it "should disable autotagging if new tags are blank" do
      MerchantUser.should_receive(:disable_autotags).with(@current_user, @merchant, -1)
      put :update, :id => @merchant.id, :sign => @sign, :autotags => "", :old_tags => @old_tags
    end

    it "should not force off any tags if the new tags are blank" do
      AccountMerchantTagStat.should_not_receive(:force_off)
      put :update, :id => @merchant.id, :sign => @sign, :autotags => "", :old_tags => @old_tags
    end

    it "should re-enable autotagging if new tags are not blank" do
      MerchantUser.should_receive(:enable_autotags).with(@current_user, @merchant, -1)
      put :update, :id => @merchant.id, :sign => @sign, :autotags => @autotags, :old_tags => @old_tags
    end
  end
end
