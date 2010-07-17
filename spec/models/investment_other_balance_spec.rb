require 'spec_helper'

describe InvestmentOtherBalance do
  before(:each) do
    @investment_other_balance = InvestmentOtherBalance.new
  end

  it "should be valid" do
    @investment_other_balance.should be_valid
  end
end
