require 'spec_helper'

describe UserProfile do
  before(:each) do
    @user = User.make
    @up = UserProfile.new
    @up.user = @user
  end

  it "should be valid" do
    @up.should be_valid
  end

  it "should have a user" do
    @up.user = @user
    @up.user.should == @user
  end

  it "should have a website" do
    @up.website = "www.wesabe.com"
    @up.website.should == "www.wesabe.com"
  end

  it "should add http to urls without it" do
    @up.update_attribute(:website, "www.wesabe.com")
    @up.website == "http://www.wesabe.com"
  end

  it "should verify that the url is valid" do
    @up.update_attribute(:website, "hey there friend")
    @up.website.should be_nil
  end

  it "should verify that the url is http/https" do
    @up.update_attribute(:website, "javascript:stealIdentity()")
    @up.website.should be_nil

    @up.update_attribute(:website, "https://www.wesabe.com/")
    @up.website.should == "https://www.wesabe.com/"
  end

  it "should allow clearing the website" do
    @up.update_attribute(:website, "www.wesabe.com")
    lambda{ @up.update_attribute(:website, "") }.should change(@up, :website).from("http://www.wesabe.com").to(nil)
  end

end
