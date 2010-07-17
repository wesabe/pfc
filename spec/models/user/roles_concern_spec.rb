require 'spec_helper'

describe User, "with no special role" do
  before do
    @user = User.new
  end

  it "should not be an admin" do
    @user.should_not be_an_admin
  end
end

describe "An Admin user" do
  before do
    @user = User.new
    @user.admin = true
  end

  it "should be an admin" do
    @user.should be_an_admin
  end
end