require 'spec_helper'

describe UserPreferencesController, "#route_for" do

  it "should map { :controller => 'user_preferences', :action => 'index', :format => 'xml' } to /preferences.xml" do
    route_for(:controller => "user_preferences", :action => "index", :format => 'xml').should == "/preferences.xml"
  end

  it "should map { :controller => 'user_preferences', :action => 'show', :preference => 'foo', :format => 'xml' } to /preferences/foo.xml" do
    route_for(:controller => "user_preferences", :action => "show", :preference => 'foo', :format => 'xml').should == "/preferences/foo.xml"
  end

  it "should map { :controller => 'user_preferences', :action => 'update'} to /preferences" do
    route_for(:controller => "user_preferences", :action => "update").should == {:path => "/preferences", :method => :post}
  end


  it "should map { :controller => 'user_preferences', :action => 'toggle', :preference => 'foo'} to /preferences/toggle/foo" do
    route_for(:controller => "user_preferences", :action => "toggle", :preference => "foo").should == {:path => "/preferences/toggle/foo", :method => :put}
  end
end

describe UserPreferencesController, "handling GET /preferences.xml" do
  it_should_behave_like "it has a logged-in user"

  before do
    @user_preferences = @current_user.preferences
  end

  def do_get
    @request.env["HTTP_ACCEPT"] = "application/xml"
    get :index
  end

  it "should be successful" do
    do_get
    response.should be_success
  end

  it "should assign user_preferences" do
    do_get
    assigns[:preferences].should == @user_preferences.preferences
  end

  it "should render the found user_preferences as xml" do
    do_get
    response.body.should == @user_preferences.preferences.to_xml(:root => "preferences")
  end
end

describe UserPreferencesController, "handling GET /preferences/:preference.xml" do
  it_should_behave_like "it has a logged-in user"

  before do
    @user_preferences = mock_model(UserPreferences)
    UserPreferences.stub!(:find).and_return(@user_preferences)
    @desired_preferences = {:foo => 'bar'}
    @user_preferences.stub!(:preferences).and_return(@desired_preferences.merge(:baz => true))
    @current_user.stub!(:preferences).and_return(@user_preferences)
    @user_preferences.stub!(:tester_access).and_return(false)
  end

  def do_get
    @request.env["HTTP_ACCEPT"] = "application/xml"
    get :show, :preference => 'foo'
  end

  it "should be successful" do
    do_get
    response.should be_success
  end

  it "should find user_preferences" do
    @current_user.should_receive(:preferences).and_return(@user_preferences)
    do_get
  end

  it "should render the found user_preference as xml" do
    do_get
    response.body.should == @desired_preferences.to_xml(:root => 'preferences')
  end
end

describe UserPreferencesController, "handling POST /preferences to update a user's preferences" do
  it_should_behave_like "it has a logged-in user"

  before do
    @user_preferences = mock_model(UserPreferences, :to_param => "1")
    UserPreferences.stub!(:new).and_return(@user_preferences)
    @user_preferences.stub!(:preferences).and_return({})
    @user_preferences.stub!(:update_preferences).and_return(@user_preferences)
    @current_user.stub!(:preferences).and_return(@user_preferences)
    @user_preferences.stub!(:tester_access).and_return(false)
  end

  def post_preferences
    @user_preferences.should_receive(:foo).and_return('bar')
    post :update, :foo => 'bar'
  end

  it "should update the user's preferences" do
    @user_preferences.should_receive('update_preferences').and_return(@user_preferences)
    post_preferences
    assert_equal 'bar', @user_preferences.foo
  end
end


describe UserPreferencesController, "handling PUT /preferences/toggle/:preference" do
  it_should_behave_like "it has a logged-in user"

  before do
    @user_preferences = UserPreferences.create(:user => @current_user)
    @current_user.stub!(:preferences).and_return(@user_preferences)
  end

  def toggle_preference
    put :toggle, :preference => "foo"
  end

  it "should toggle the preference" do
    @user_preferences.foo.should be_nil
    toggle_preference
    @user_preferences.foo.should be_true
    toggle_preference
    @user_preferences.foo.should be_false
  end
end
