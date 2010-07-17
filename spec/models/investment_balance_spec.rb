require 'spec_helper'

describe InvestmentBalance do
  before(:each) do
    @investment_balance = InvestmentBalance.new
  end

  it "should be valid" do
    @investment_balance.should be_valid
  end
end
