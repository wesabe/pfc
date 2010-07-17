require 'spec_helper'

describe Txaction::MonthPaginator do

  before(:each) do
    @paginator = Txaction::MonthPaginator.new(2007, 6)
  end

  it "should have a limit" do
    @paginator.limit.should be(30)
  end

  it "should have an offset" do
    @paginator.offset.should be(0)
  end

  it "should accept page as a string" do
    @paginator = Txaction::MonthPaginator.new(2007, 6, "3")
    @paginator.offset.should == 60
  end

  it "should default page to 1 if passed a blank string" do
    @paginator = Txaction::MonthPaginator.new(2007, 6, "")
    @paginator.offset.should == 0
  end

  it "should default page to 1 if passed a negative number" do
    @paginator = Txaction::MonthPaginator.new(2007, 6, -10)
    @paginator.offset.should == 0
  end

  it "should select all txactions for the month" do
    @paginator.conditions.should == { "txactions.date_posted" => Time.mktime(2007, 6, 1)..Time.mktime(2007, 6, 1).end_of_month }
  end

  it "should default to this month if year/month is invalid" do
    @paginator = Txaction::MonthPaginator.new(2008, "*")
    @paginator.conditions.should == { "txactions.date_posted" => Time.now.beginning_of_month..Time.now.end_of_month }
  end
end