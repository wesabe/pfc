require 'spec_helper'

describe UploadsController, "#route_for" do
  it "should map { :controller => 'uploads', :action => 'index' } to /uploads" do
    route_for(:controller => "uploads", :action => "index").should == "/uploads"
  end

  it "should map { :controller => 'uploads', :action => 'index', :account_id => '1' } to /uploads/account/1" do
    route_for(:controller => "uploads", :action => "index", :account_id => "1").should == "/uploads/account/1"
  end

  it "should map { :controller => 'uploads', :action => 'new' } to /uploads/new" do
    route_for(:controller => "uploads", :action => "new").should == "/uploads/new"
  end

  it "should map { :controller => 'uploads', :action => 'show', :id => '1' } to /uploads/1" do
    route_for(:controller => "uploads", :action => "show", :id => "1").should == "/uploads/1"
  end
end


describe UploadsController, 'handling GET /uploads/account/1' do
  it_should_behave_like "it has a logged-in user"

  before(:each) do
    @account = mock_model(Account, :last_balance => 0, :uploads => [])
    Account.stub!(:find).and_return(@account)
    @current_user.stub!(:account).and_return(@account)
  end

  it "should render the index page" do
    get :index, :account_id => 1
    response.should render_template('uploads/index')
  end
end

describe UploadsController, 'handling GET /uploads/select' do
  it_should_behave_like "it has a logged-in user"

  before do
    @new1 = stub_model(Account, :status => 0, :newly_created_by? => true)
    @new2 = stub_model(Account, :status => 0, :newly_created_by? => true)
    @new3 = stub_model(Account, :status => 5, :newly_created_by? => false)
    @old1 = stub_model(Account, :status => 0, :newly_created_by? => false)
    @old2 = stub_model(Account, :status => 0, :newly_created_by? => false)
    @old3 = stub_model(Account, :status => 0, :newly_created_by? => false)
    @accounts = [@new1, @new2, @new3, @old1, @old2, @old3]

    # job got all accounts
    @job = mock_model(SsuJob, :accounts => @accounts)

    # cred is hooked up to all accounts
    @cred = stub_model(AccountCred, :accounts => @accounts, :last_job => @job)
    AccountCred.stub!(:find_by_account_key_and_cred_guid).and_return(@cred)
    @current_user.stub!(:account_key).and_return('010101')
  end

  it "lists newly created vs. existing accounts" do
    get :select, :cred => '12345'
    # make sure the before_filter didn't redirect us
    response.should be_success

    assigns[:new_accounts].should == [@new1, @new2, @new3]
    assigns[:old_accounts].should == [@old1, @old2, @old3]
  end
end

describe UploadsController, "new upload screens" do
  it_should_behave_like "it has a logged-in user"

  it "should ask for the name of your finanacial institution" do
    request.stub!(:user_agent).and_return("Mozilla/5.0 (Macintosh; U; Intel Mac OS X; en-us) AppleWebKit/523.10.3 (KHTML, like Gecko) Version/3.0.4 Safari/523.10")
    get :new
    response.should be_success
  end
end

describe UploadsController, "FI redirection" do
  it_should_behave_like "it has a logged-in user"

  before do
    @fi = FinancialInst.new(:ssu_support => FinancialInst::SSUSupport::NONE, :wesabe_id => "us-001")
    FinancialInst.stub!(:find_for_user).and_return(@fi)
    @current_user.stub!(:employee?).and_return(false)
    controller.stub!(:ssu_enabled?).and_return(true)
  end

  it "should show an error message when no FI name is given" do
    FinancialInst.should_receive(:find_for_user).and_return(nil)
    post :choose, :fi_name => ''
    flash[:error].should_not be_empty
    response.should redirect_to(new_upload_path)
  end

  it "should redirect users with SSU FIs to the SSU page" do
    @fi.should_receive(:ssu_support?).and_return(FinancialInst::SSUSupport::GENERAL)
    post :choose, :fi_name => "Wells Fargo"
    response.should redirect_to(ssu_new_upload_path(:fi => @fi))
  end

  it "should not redirect users with SSU FIs to the SSU page when SSU is disabled" do
    controller.stub!(:ssu_enabled?).and_return(false)
    @fi.stub!(:connection_type).and_return("Automatic")
    post :choose, :fi_name => "Wells Fargo"
    response.should_not redirect_to(ssu_new_upload_path(:id => @fi.wesabe_id))
  end

  it "should redirect FIs that can't be scraped to the manual page" do
    @fi.should_receive(:connection_type).and_return("Manual")
    post :choose, :fi_name => "Wells Fargo"
    response.should redirect_to(manual_upload_path(:fi => @fi))
  end

end
