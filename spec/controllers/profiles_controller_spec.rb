require 'spec_helper'

describe ProfilesController do
  describe "GET /profile/edit" do
    it_should_behave_like "it has a logged-in user"

    it "renders the profile edit page for the user" do
      get :edit
      assigns[:user].should == current_user
      response.should render_template("edit")
    end
  end
end