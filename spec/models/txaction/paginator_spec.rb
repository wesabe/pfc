require 'spec_helper'

describe Txaction::Paginator do

  before(:each) do
    @paginator = Txaction::Paginator.new(2)
  end

  it "should have a limit of 30" do
    @paginator.limit.should == 30
  end

  it "should have an offset of 30" do
    @paginator.offset.should == 30
  end

  it "should have no conditions" do
    @paginator.conditions.should == {}
  end
end