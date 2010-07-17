require 'spec_helper'

class TestController < ApplicationController
  include Authentication::ControllerMethods

  def test
    render :text => "worked"
  end

  def test_clear_current_user
    clear_current_user
    render :text => "cleared current user"
  end

  def test_set_current_user
    set_current_user(User.find(params[:user_id]))
    render :text => "current user set"
  end

  def test_set_current_user_without_session
    set_current_user(User.find(params[:user_id]))
  end

  def test_render_not_authorized
    render_not_authorized
  end

  def authenticated_action
    render :text => "authenticated"
  end
  before_filter :check_authentication, :only => :authenticated_action

end

describe TestController, :type => :controller do
  describe Authentication::ControllerMethods do

    describe "check_authentication before filter" do
      context "without a logged-in user" do
        it "should redirect to signup URL" do
          get :authenticated_action
          response.should redirect_to(signup_url)
        end

        it "should record the intended_url in the session" do
          get :authenticated_action
          controller.session[:intended_uri].should == request.fullpath
        end

        it "should not record the intended url for xhr requests" do
          xhr :get, :authenticated_action
          controller.session[:intended_uri].should be_nil
        end

        it "should not record the intended url for urls ending in .xml" do
          request.stub!(:fullpath).and_return("/foo.xml")
          get :authenticated_action
          controller.session[:intended_uri].should be_nil
        end

        it "should not record the intended url for /user/login" do
          request.stub!(:fullpath).and_return("/user/login")
          get :authenticated_action
          controller.session[:intended_uri].should be_nil
        end

        it "should not record the intended url for /user/logout" do
          request.stub!(:fullpath).and_return("/user/logout")
          get :authenticated_action
          controller.session[:intended_uri].should be_nil
        end

        it "should not record the intended url for /user/timeout" do
          request.stub!(:fullpath).and_return("/user/timeout")
          get :authenticated_action
          controller.session[:intended_uri].should be_nil
        end

        it "should not record the intended url for /user/ping" do
          request.stub!(:fullpath).and_return("/user/ping")
          get :authenticated_action
          controller.session[:intended_uri].should be_nil
        end
      end

      context "without a member cookie" do
        it "should redirect to login URL" do
          cookies[:wesabe_member] = true
          get :authenticated_action
          response.should redirect_to(login_url)
        end
      end

      context "with a logged in user" do
        it_should_behave_like "it has a logged-in user"
        it "should allow the action" do
          get :authenticated_action
          response.body.should == "authenticated"
        end
      end
    end

  end
end

describe TestController, :type => :controller do
  describe Authentication::ControllerMethods, "included" do

    before(:each) do
      @user = User.make
      request.session[:user] = @user.id
    end

    after(:each) do
      @user.destroy
    end

    describe "set_current_user method" do
      it "should set the current user" do
        get :test_set_current_user, :user_id => @user.id
        controller.send(:current_user).should == @user
        User.current.should == @user
      end

      it "should set the current user without a session" do
        request.session = {}
        get :test_set_current_user_without_session, :user_id => @user.id
        User.current.should == @user
      end
    end

    describe "current_user_id method" do
      it "should return the value for key :user in the session hash" do
        get :test
        response.session[:user] = @user.id
        controller.send(:current_user_id).should == @user.id
      end
    end

    describe "clear_current_user method" do
      it "should set current_user to nil" do
        request.session[:user] = @user.id
        get :test
        controller.current_user.should_not be_nil
        get :test_clear_current_user
        controller.current_user.should be_nil
      end
    end

    describe "render_not_authorized method" do
      it "should return a 401 to non-XHR requests" do
        get :test_render_not_authorized
        response.should be_unauthorized
        response.body.should be_blank
      end

      it "should return a redirect to XHR requests" do
        request.stub!(:xhr?).and_return(true)
        get :test_render_not_authorized
        response.should redirect_to(login_url)
      end
    end

  end
end
