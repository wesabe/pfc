require 'spec_helper'

describe Txaction, "a new Txaction" do
  it_should_behave_like "it has a logged-in user"

  before do
    @account = Account.make
    @txaction = Txaction.new(:account => @account)
  end

  it "date_posted should return fi_date_posted if date_posted isn't set" do
    @txaction.fi_date_posted = Time.now
    @txaction.date_posted.should == @txaction.fi_date_posted
  end

  it "fi_date_posted should return date_posted if fi_date_posted isn't set" do
    @txaction.date_posted = Time.now
    @txaction.fi_date_posted.should == @txaction.date_posted
  end

  it "should set fi_date_posted to date_posted if date_posted is set and fi_date_posted isn't" do
    @txaction.date_posted = Time.now
    @txaction.read_attribute(:fi_date_posted).should be_nil
    @txaction.save!
    @txaction.read_attribute(:fi_date_posted).should == @txaction.date_posted
  end

  it "should set date_posted to fi_date_posted if fi_date_posted is set and date_posted isn't" do
    @txaction.fi_date_posted = Time.now
    @txaction.read_attribute(:date_posted).should be_nil
    @txaction.save!
    @txaction.read_attribute(:date_posted).should == @txaction.fi_date_posted
  end

  it "should not reset date_posted or fi_date_posted if they are already set" do
    one_month_ago = 1.month.ago
    two_months_ago = 2.months.ago
    @txaction.date_posted = one_month_ago
    @txaction.fi_date_posted = two_months_ago
    @txaction.save!
    @txaction.date_posted.should == one_month_ago
    @txaction.fi_date_posted.should == two_months_ago
  end

  it "should throw a validation exception of niether date_posted nor fi_date_posted are set" do
    lambda {@txaction.save!}.should raise_error(ActiveRecord::RecordInvalid)
  end
end

describe Txaction do
  it_should_behave_like "it has a logged-in user"

  before do
    @txaction = Txaction.make(:date_posted => 1.month.ago)
  end

  it "changed_date_posted? should return false if the fi_date_posted was never set" do
    @txaction.changed_date_posted?.should be_false
  end

  it "changed_date_posted? should return false if the date_posted hasn't changed" do
    @txaction.fi_date_posted = @txaction.date_posted
    @txaction.changed_date_posted?.should be_false
  end

  it "changed_date_posted? should return true if the date_posted has been changed" do
    @txaction.fi_date_posted = @txaction.date_posted - 1.day
    @txaction.changed_date_posted?.should be_true
  end
end
