require 'spec_helper'

describe UserPreferences do
  before do
    @user_preferences = UserPreferences.new(:user => mock_model(User))
  end

  it "should be valid" do
    @user_preferences.should be_valid
  end

  it "should not be valid without a user" do
    @user_preferences.user = nil
    @user_preferences.should_not be_valid
  end

  it "should set a scalar preference" do
    @user_preferences.foobar = true
    assert @user_preferences.foobar
    assert @user_preferences.foobar?
  end

  it "should set a non-scalar preference" do
    @user_preferences.foobar = [1,2,3]
    @user_preferences.foobar.should be_an_instance_of(Array)
    @user_preferences.foobar.should have(3).items
  end

  it "should match both sym and string keys" do
    @user_preferences.preferences = {:a => true, "b" => true}
    assert @user_preferences.a?
    assert @user_preferences.b?
    assert @user_preferences.a
    assert @user_preferences.b
  end

  it "should convert true and false strings to booleans" do
    @user_preferences.preferences = {"a" => "true", "b" => "false"}
    assert @user_preferences.a?
    assert !@user_preferences.b?
  end

  it "should toggle a preference" do
    @user_preferences.preferences = {"a" => "true", "b" => "false"}
    @user_preferences.toggle(:a).should be_false
    @user_preferences.toggle(:a).should be_true
    @user_preferences.toggle(:b).should be_true
    @user_preferences.toggle(:b).should be_false
    @user_preferences.toggle(:new_key).should be_true
  end

  it "allows updating preferences in bulk" do
    @user_preferences.update_preferences :foo => 'true', :bar => [1,2,3]
    @user_preferences.foo.should be_true
    @user_preferences.bar.should == [1,2,3]
  end
end
