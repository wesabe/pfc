require 'spec_helper'

describe Money::Formatter do
  def format(money, options={})
    return Money::Formatter.format(money, options)
  end

  before do
    @fiveUSD = Money.new(5, 'USD')
    @minusTwoUSD = Money.new(-2, 'USD')
    @oneMillionGBP = Money.new(1_000_000, 'GBP')
  end

  describe ".format" do
    it "initializes a Money::Formatter and calls format on it" do
      Money::Formatter.format(@fiveUSD, :precision => 0).should == "$5"
    end
  end

  describe "#format" do
    it "allows using a custom separator" do
      format(@fiveUSD, :separator => ',').should == "$5,00"
    end

    it "allows using a custom delimiter" do
      format(@oneMillionGBP, :delimiter => '!').should == "£1!000!000.00"
    end

    it "allows using a custom unit" do
      format(@oneMillionGBP, :unit => '$$').should == "$$1,000,000.00"
    end

    it "allows showing the currency name" do
      format(@fiveUSD, :show_currency => true).should == "USD $5.00"
      format(@oneMillionGBP, :show_currency => true).should == "GBP £1,000,000.00"
    end

    describe "with large amounts" do
      it "uses a separator if the currency calls for it" do
        format(@oneMillionGBP).should == "£1,000,000.00"
      end
    end

    describe "with default options" do
      it "shows the unit and uses the default separator, delimiter, negation, and precision of the currency" do
       format(@minusTwoUSD).should == "-$2.00"
      end
    end

    describe "given the hide_unit option" do
      it "does not include the currency unit" do
        format(@fiveUSD, :hide_unit => true).should == "5.00"
      end
    end

    describe "given the hide_delimiter option" do
      it "does not include the delimiter" do
        format(@oneMillionGBP, :hide_delimiter => true).should == "£1000000.00"
      end
    end

    describe "given the as_decimal option" do
      it "is a shortcut for hide_unit and hide_delimiter" do
        format(@oneMillionGBP, :as_decimal => true).should == "1000000.00"
      end
    end

    describe "given the negative_parens option" do
      it "wraps negative numbers in parentheses" do
        format(@minusTwoUSD, :negative_parens => true).should == "($2.00)"
      end
    end

    describe "with 0 precision" do
      it "does not include a separator" do
        format(@fiveUSD, :precision => 0).should == "$5"
      end
    end

    describe "with 5 precision" do
      it "includes 5 decimal points" do
        format(@fiveUSD, :precision => 5).should == "$5.00000"
      end
    end
  end
end
