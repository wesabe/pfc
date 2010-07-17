require 'spec_helper'

describe MerchantUser do
  describe "disable_autotags class method" do
    before do
      @merchant_user = MerchantUser.make
    end

    it "should set the disable_autotags flag" do
      @merchant_user.autotags_disabled?.should be_false
      MerchantUser.disable_autotags(@merchant_user.user, @merchant_user.merchant, @merchant_user.sign)
      @merchant_user.reload.autotags_disabled?.should be_true
    end
  end
end
