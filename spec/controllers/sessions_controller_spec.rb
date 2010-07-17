require 'spec_helper'

describe SessionsController do
  before do
    @user = User.make(:username => 'first')
    @user.change_password!('first')
  end

  include SetReferrer

  it "displays the login page" do
    get :new
    response.should be_success
    response.should render_template('new')
  end

  it "allows login with valid username and password" do
    post :create, :username => 'first', :password => 'first'
    session[:user].should_not be_nil
    response.should redirect_to(dashboard_url)
  end

  it "should not login with bad username or password" do
    post :create, :username => 'first', :password => 'foo'
    session[:user].should be_nil
    response.should be_success
    response.should render_template('new')
  end

  context 'when the user is already logged in' do
    it_should_behave_like 'it has a logged-in user'

    it 'does not log in again' do
      post :create, :username => 'first', :password => 'first'
      response.should redirect_to(dashboard_url)
    end

    it 'returns an empty ping' do
      xhr :get, :show
      response.should be_success
      response.should be_blank
    end

    it 'redirects on ping if user has been timed out' do
      session[:expires_at] = 10.minutes.ago
      xhr :get, :show
      response.should be_success
      response.body.should == '/*-secure- window.location.href = "http://test.host/timeout"; */'
    end

    it "allows user logout" do
      get :delete
      response.should redirect_to(login_url(:signed_out => true))
      session[:user].should be_nil
    end
  end

  it "should redirect to intended uri on login" do
    set_intended 'http://www.thingymajig.woo/hah'
    post :create, :username => 'first', :password => 'first'
    session[:user].should_not be_nil
    response.should redirect_to('http://www.thingymajig.woo/hah')
  end

  it "should not redirect to timeout on login" do
    set_intended '/user/timeout'
    post :create, :username => 'first', :password => 'first'
    session[:user].should_not be_nil
    response.should redirect_to(dashboard_url)
  end

  it "does not redirect to logout on login" do
    set_intended '/user/logout'
    post :create, :username => 'first', :password => 'first'
    session[:user].should_not be_nil
    response.should redirect_to(dashboard_url)
  end

  it "should logout users" do
    login
    get :delete
    response.should redirect_to(login_url(:signed_out => true))
    session[:user].should be_nil
  end

  it "should timeout users" do
    login
    session[:expires_at] = 50.minutes.ago
    get :delete, :reason => :timeout
    response.should redirect_to(login_url)
    session[:user].should be_nil
  end

  it "should not display timeout error to people who logged out a long time ago" do
    login
    session[:expires_at] = 50.hours.ago
    get :delete, :reason => :timeout
    response.should redirect_to(login_url)
    session[:user].should be_nil
    session["flash"][:error].should be_nil
  end

  it "should redirect non-xhr requests to the homepage" do
    get :show
    response.should redirect_to(root_url)
  end

  it "calls the user's after_login method if the user was not previously logged in" do
    user = User.generate_authenticated!
    User.stub!(:authenticate).and_return(user)
    user.should_receive(:after_login)
    post :create, :username => 'first', :password => 'first'
  end

  it "does not call the user's after_login method if the user was previously logged in" do
    user = User.generate_authenticated!

    User.stub!(:authenticate)
    login(:first)
    user = users_with_account_key(:first)
    User.stub!(:authenticate).and_return(user)
    user.should_not_receive(:after_login)
    post :create, :username => 'first', :password => 'first'
  end

  it "should reset the session after login to avoid session fixation" do
    session[:reset_me] = "foo"
    post :create, :username => 'first', :password => 'first'
    session[:reset_me].should be_nil
  end
end

describe SessionsController, "login" do
  before do
    @user = User.make(:security_answers_hash => "abc")
  end

  it "should allow login with email address" do
    post :create, :username => @user.email, :password => @user.password
    session[:user].should_not be_nil
    response.should redirect_to(dashboard_url)
  end

  it "should redirect pending users to reset_password" do
    @user.pending!(true)
    post :create, :username => @user.username, :password => @user.password
    response.should redirect_to("/user/reset_password")
  end
end

describe SessionsController, "login with ssu credentials" do
  before do
    @user = users_with_account_key(:user_with_ssu_creds)
    @citibank_creds = account_creds(:citibank)
    @citibank_creds.stub!(:destroy)
    @citibank_creds.update_attribute :account_key, @user.account_key
    User.should_receive(:authenticate).and_return(@user)
    controller.stub!(:ssu_enabled?).and_return(true)
  end

  it "should start jobs for credentials without any previous jobs" do
    SsuJob.should_receive(:start).with(@user, @citibank_creds)
    post :create, :username => @user.username, :password => @user.username
  end

  it "should not start jobs if SSU is disabled" do
    controller.stub!(:ssu_enabled?).and_return(false)
    SsuJob.should_not_receive(:start)
    post :create, :username => @user.username, :password => @user.username
  end

  it "should call AccountUpdateManager to start and delete jobs appropriately" do
    User::AccountUpdateManager.should_receive(:login!).with(@user, controller, :force => true)
    post :create, :username => @user.username, :password => @user.username
  end
end

describe SessionsController, "redirections from session/new" do
  include SetReferrer

  before do
    @user = User.make
    controller.stub!(:current_user).and_return(@user)
  end

  it "should redirect to accounts page if already logged in" do
    post "new"
    response.should redirect_to(dashboard_url)
  end

  it "should redirect back if already logged in and coming from a wesabe page" do
    set_referrer("http://www.wesabe.com/accounts/8")
    post "new"
    response.should redirect_to(account_url(8))
  end
end