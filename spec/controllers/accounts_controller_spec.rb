require 'spec_helper'

describe AccountsController do
  describe "GET /accounts while logged out" do
    it "should redirect to the login page" do
      controller.stub!(:current_user).and_return(nil)
      get :index
      response.should redirect_to(login_url)
    end
  end

  describe "GET /accounts while logged in" do
    it_should_behave_like "it has a logged-in user"

    before do
      @account = mock_model(Account,
        :name => "The Best Account", :[] => "USD", :guid => 'edcba',
        :financial_inst_id => 1,
        :status => Constants::Status::ACTIVE)
      current_user.stub!(:account).and_return(@account)
      current_user.stub!(:active_accounts).and_return([@account])
      current_user.stub!(:archived_accounts).and_return([@account])
      current_user.stub!(:account_creds_in_limbo).and_return([])
      current_user.default_currency = "USD"
      current_user.stub!(:account_key).and_return('abcde')
    end

    it "should be successful" do
      get :index
      response.should be_success
      response.should render_template('index')
    end
  end

  describe "POST /accounts" do
    it_should_behave_like "it has a logged-in user"

    before do
      request.accept = "application/json"
    end

    describe "a json request" do
      it "should create a cash account" do
        post :create, :name => "My Cash Account", :currency => "USD"
        response.should be_success
        response.content_type.should == "application/json"
        response.body.should match_json(hash_including('guid' => assigns[:account].guid))
      end

      it "should create a manual account if a balance is provided" do
        post :create, :name => "My Manual Account", :currency => "USD", :balance => "42"
        response.should be_success
        response.content_type.should == "application/json"
        response.body.should match_json(hash_including('guid' => assigns[:account].guid))
        assigns[:account].should have_balance
        assigns[:account].balance.to_d.should == 42.to_d
      end

      it "should default to USD if no currency is provided" do
        post :create, :name => "My Cash Account"
        response.should be_success
        assigns[:account].currency.should == "USD"
      end

      it "should default to USD if an unknown currency is provided" do
        post :create, :name => "My Cash Account", :currency => "---"
        response.should be_success
        assigns[:account].currency.should == "USD"
      end

      it "should return an error if no name is provided" do
        post :create
        response.should be_bad_request
        response.body.should match(/Name can't be blank/)
      end

    end
  end

  describe "GET /accounts/<id>" do
    it_should_behave_like "it has a logged-in user"

    before do
      @account = Account.make(:user => current_user)
    end

    it "redirects to the accounts page with an anchor" do
      get :show, :id => @account.to_param
      response.should redirect_to(accounts_url(:anchor => account_path(@account)))
    end
  end

  describe "GET /accounts/<guid>" do
    it_should_behave_like "it has a logged-in user"

    before do
      @account = Account.make(:user => current_user)
    end

    it "redirects to the accounts page with an anchor" do
      get :show, :id => @account.guid
      response.should redirect_to(accounts_url(:anchor => account_path(@account)))
    end

    it "should redirect to index page if account not found" do
      get :show, :id => ActiveSupport::SecureRandom.hex(64)
      response.should redirect_to(accounts_url)
    end
  end

  describe "DELETE /accounts/<id>" do
    before do
      @current_user = User.make
    end

    it_should_behave_like "it has a logged-in user"

    before(:each) do
      @account = Account.make(:user => current_user)
    end

    it "should delete the account" do
      delete :destroy, :id => @account.to_param, :password => @current_user.password
      Account.find_by_id(@account.id).should be_nil
    end

    it "should require a password" do
      delete :destroy, :id => @account.to_param
      response.should be_forbidden
      Account.find_by_id(@account.id).should_not be_nil
    end
  end

  describe "POST /accounts/enable" do
    it_should_behave_like "it has a logged-in user"

    it "does not raise an exception when there are no accounts to act on" do
      post :enable
      response.should redirect_to(dashboard_url)
    end
  end

  describe "GET /accounts/<id>/financial_institution_site" do
    it_should_behave_like "it has a logged-in user"

    before do
      @account = Account.make(:user => current_user)
    end

    it "redirects to the account's financial institution url" do
      get :financial_institution_site, :id => @account.to_param
      response.should redirect_to(@account.financial_inst.url)
    end

    describe "when <id> is for a cash account" do
      before do
        @account = Account.make(:cash, :user => current_user)
      end

      it "returns a 404 Not Found" do
        get :financial_institution_site, :id => @account.to_param
        response.should be_not_found
      end
    end

    describe "when the account does not exist" do
      before do
        @account.destroy
      end

      it "returns a 404 Not Found" do
        get :financial_institution_site, :id => @account.to_param
        response.should be_not_found
      end
    end
  end
end