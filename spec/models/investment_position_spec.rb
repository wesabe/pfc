require 'spec_helper'

describe InvestmentPosition do
  before(:each) do
    @investment_position = InvestmentPosition.new
  end

  it "should be valid" do
    @investment_position.should be_valid
  end
end
