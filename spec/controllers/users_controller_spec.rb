require 'spec_helper'

describe UsersController do
  before do
    User.delete_all
  end

  describe "POST /user" do
    before do
      @existing_user = User.make
    end

    it "should return Bad Request if the username is blank" do
      post "create"
      response.should be_bad_request
      response.body.should match(%r{Username can't be blank})
    end

    it "should return Bad Request if the username is taken" do
      post "create", :username => @existing_user.username
      response.should be_bad_request
      response.body.should match(%r{Username has already been taken})
    end

    it "should return Bad Request if the email is blank" do
      post "create"
      response.should be_bad_request
      response.body.should match(%r{Email can't be blank})
    end

    it "should return Bad Request if the email is taken" do
      post "create", :email => @existing_user.email
      response.should be_bad_request
      response.body.should match(%r{Email already in use})
    end

    it "should return Bad Request if the password is blank" do
      post "create"
      response.should be_bad_request
      response.body.should match(%r{Password can't be blank})
    end

    it "should return OK if the user was created successfully" do
      post "create", :username => "bobbob", :email => "bob@bob.com", :password => "sekr3t"
      response.should be_success
    end
  end

  describe "POST /signup" do
    context "when signup fails for some reason" do
      it "shows them the signup form again" do
        post :create
        response.should render_template("user/new")
      end

      context "given a name" do
        it "passes the view a User with the given name" do
          post :create, :user => {:name => "Hank"}
          assigns(:user).name.should == "Hank"
        end
      end

      context "not given a display name" do
        it "passes the view a User with a blank name" do
          post :create
          assigns(:user).name.should be_blank
        end
      end
    end
  end

  describe "GET /profile/:name" do
    context "requested by a logged-in user" do
      it_should_behave_like "it has a logged-in user"

      before do
        @user = User.make
      end

      it "renders the profile for the viewed user" do
        get :show, :id => @user.name
        assigns[:user].should == @user
        response.should render_template('show')
      end

      context "given an invalid name" do
        it "raises" do
          lambda { get :show, :id => 'yabba dabba doo' }.
            should raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end
  end

  describe "PUT /profile" do
    it_should_behave_like "it has a logged-in user"

    it "should require a password to change the email address" do
      put 'update', :email_change => {:password => '', :email => "foo@bar"}
      assert assigns[:email_change].errors.size > 0
    end

    it "should not allow an incorrect password to change the email address" do
      current_user.should_receive(:valid_password?).with("asdf").and_return(false)
      put 'update', :email_change => {:password => 'asdf', :email => "foo@bar"}
      assert assigns[:email_change].errors.size > 0
    end

    it "should allow email address to be changed with correct password" do
      current_user.should_receive(:valid_password?).with("asdf").and_return(true)
      current_user.should_receive(:update_attributes).with("email" => "foo@bar")
      put 'update', :user => {}, :photo => {}, :email_change => {:password => 'asdf', :email => "foo@bar"}
    end
  end

  describe "PUT /password" do
    it_should_behave_like "it has a logged-in user"

    it "changes the password if the current password is correct" do
      put :update_password, :password_change => {
        :current_password => 'abcdefg', :password => 'newpass', :password_confirmation => 'newpass'}

      User.authenticate(current_user.email, 'newpass').should == current_user
    end

    it "does not change the password if the current password is wrong" do
      put :update_password, :password_change => {
        :current_password => '8888888', :password => 'newpass', :password_confirmation => 'newpass'}

      User.authenticate(current_user.email, 'newpass').should be_nil
    end
  end

  describe UsersController, "GET /user/destroy" do
    it_should_behave_like "it has a logged-in user"

    it "should return the confirm_delete partial" do
      get :destroy
      response.should render_template("layouts/application", "user/delete_membership")
    end
  end

  describe UsersController, "DELETE /user" do
    it_should_behave_like "it has a logged-in user"

    def do_delete(password)
      delete :destroy, :password => password
    end

    it "redirects to the homepage" do
      do_delete(current_user.password)
      response.should redirect_to(root_url)
    end

    it "should delete the user with a correct password" do
      do_delete(current_user.password)
      current_user.reload.username.should match(/^deleted_user/)
    end

    it "should fail with an incorrect password" do
      do_delete("badpass")
      response.should render_template("layouts/application", "user/delete_membership")
    end

    it "should not delete the account with an incorrect password" do
      do_delete("badpass")
      current_user.reload.username.should_not match(/^deleted_user/)
    end
  end

  describe "GET /user/userbar" do
    it "should not require being logged in" do
      get :userbar
      response.should be_success
    end
  end
end