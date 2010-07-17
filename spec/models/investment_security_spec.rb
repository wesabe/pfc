require 'spec_helper'

describe InvestmentSecurity do
  before(:each) do
    @investment_security = InvestmentSecurity.make
  end

  it "should be valid" do
    @investment_security.should be_valid
  end

  it "should have real specs"
end
