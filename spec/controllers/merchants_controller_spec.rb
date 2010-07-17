require 'spec_helper'

describe MerchantsController do
  it_should_behave_like "it has a logged-in user"

  before do
    @account = Account.make(:user => current_user)
    @merchants = [Merchant.make, Merchant.make]
    @txactions = [
      Txaction.make(:account => @account, :merchant => @merchants[0]),
      Txaction.make(:account => @account, :merchant => @merchants[1])
    ]
  end

  describe "GET /merchants/my" do
    it "should succeed" do
      get :user_index
      response.should be_success
    end

    it "should return a json array of merchants" do
      get :user_index
      response.body.should match_json(@merchants.map(&:name).sort)
    end
  end

  describe "GET /merchants/public" do
    it_should_behave_like "it has a logged-in user"

    before do
      Merchant.destroy_all
      Rails.cache.clear
      @merchant = Merchant.make(:publicly_visible => true, :unedited => false)
    end

    it "should succeed" do
      get :public_index
      response.should be_success
    end

    it "should return a json array of merchants, excluding the user's merchants" do
      get :public_index
      response.body.should match_json([@merchant.name])
    end
  end
end