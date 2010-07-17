require 'spec_helper'

describe UserLogin do
  before(:each) do
    @user_login = UserLogin.new(:user_id => 1, :login_date => Date.today)
  end

  it "should be valid" do
    @user_login.should be_valid
  end

  it "should require a user id" do
    @user_login.user_id = nil
    @user_login.should_not be_valid
    @user_login.errors.on(:user_id).should_not be_nil
  end

  it "should belong to a user" do
    User.should_receive(:find)
    @user_login.user
  end

  it "should set the login date at validation if it is unset" do
    @user_login.login_date = nil
    @user_login.valid?
    @user_login.login_date.should == Date.today
  end

  it "should create a UserLogin when only given a user" do
    @user = User.make
    @user_login = UserLogin.create(:user => @user)
    @user_login.should_not be_new_record
    @user_login.destroy
    @user.destroy
  end
end
