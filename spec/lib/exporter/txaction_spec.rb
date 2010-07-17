require 'spec_helper'


describe Exporter::Txaction do
  before do
    @user = User.make
    @exporter = Exporter::Txaction.new(@user, nil)
    @account = Account.make(:user => @user)
  end

  it "should find the user's account given the relative id" do
    @exporter.instance_eval { find_account(1) }.should == @account
  end
end