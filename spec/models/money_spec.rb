require 'spec_helper'

describe Money do
  before do
    @fiveUSD = Money.new(5, 'USD')
    @zeroUSD = Money.new(0, 'USD')
    @minusOneUSD = Money.new(-1, 'USD')
    @gbp = 'GBP'
    @twoPointFiveGBP = Money.new(2.5, @gbp)
    clear_currency_exchange_rates
    CurrencyExchangeRate.make(:currency => @gbp, :rate => 0.5, :date => Date.today)
  end

  it "has an amount" do
    @fiveUSD.amount.should == 5.to_d
  end

  it "has a currency" do
    @fiveUSD.currency.should == 'USD'
  end

  it "can be initialized with a Currency object" do
    lambda { Money.new(5, Currency.new('USD')) }.
      should_not raise_error
  end

  it "can negate itself" do
    (-@fiveUSD).should == Money.new(-5, 'USD')
  end

  it "equals itself" do
    @fiveUSD.should == @fiveUSD
  end

  it "equals an identical copy" do
    @fiveUSD.should == @fiveUSD.dup
  end

  it "does not equal a non-Money instance, even if the attributes match" do
    @fiveUSD.should_not == stub(:money, :amount => @fiveUSD.amount, :currency => @fiveUSD.currency)
  end

  it "is not mixed" do
    @fiveUSD.should_not be_mixed
  end

  it "is convertible to JSON" do
    @fiveUSD.to_json.should match_insecure_json('USD' => '5.0', 'currency' => 'USD')
  end

  describe "with an invalid amount" do
    it "raises an ArgumentError" do
      lambda { Money.new(:foo, 'USD') }.
        should raise_error(ArgumentError)
    end
  end

  describe "with an invalid currency" do
    it "raises an ArgumentError" do
      lambda { Money.new(1, nil, Date.today) }.
        should raise_error(ArgumentError)
    end
  end

  describe "#convert_to_currency" do
    describe "given the same currency" do
      it "returns itself" do
        @fiveUSD.convert_to_currency('USD').should == @fiveUSD
      end
    end

    describe "given a currency with an exchange rate" do
      it "returns a new Money instance properly converted" do
        @fiveUSD.convert_to_currency(@gbp).should == @twoPointFiveGBP
      end
    end

    describe "given a currency without an exchange rate" do
      before do
        CurrencyExchangeRate.delete_all
      end

      it "returns a new Money instance with zero amount" do
        @fiveUSD.convert_to_currency('BOB').should == Money.new(0, 'BOB')
      end
    end
  end

  describe "#+" do
    describe "given a Money object with the same currency" do
      before do
        @fourUSD = @fiveUSD + @minusOneUSD
      end

      it "returns a new Money with the sum of the two amounts" do
        @fourUSD.amount.should == 4.to_d
      end

      it "returns a new Money with the same currency" do
        @fourUSD.currency.should == 'USD'
      end
    end

    describe "given a Money object with a different currency" do
      before do
        @oneGBP = Money.new(1, 'GBP')
      end

      it "returns a new Money::Bag with both amounts in different currencies" do
        bag = @fiveUSD + @oneGBP
        bag['USD'].should == @fiveUSD
        bag['GBP'].should == @oneGBP
      end

      describe "when one of the Money objects have zero amounts" do
        it "returns the non-zero Money" do
          (@oneGBP + Money.zero(Currency.usd)).should == @oneGBP
        end
      end
    end

    describe "given a Money::Bag" do
      before do
        @bag = Money::Bag.new
      end

      it "returns a Money::Bag with self added to it" do
        @bag = @fiveUSD + @bag
        @bag.currencies.should == ['USD']
        @bag['USD'].should == @fiveUSD
      end
    end

    describe "given a Float" do
      it "raises an ArgumentError" do
        lambda { @fiveUSD + 4.0 }.should raise_error(ArgumentError)
      end
    end

    describe "given a Fixnum" do
      it "raises an ArgumentError" do
        lambda { @fiveUSD + 4 }.should raise_error(ArgumentError)
      end
    end
  end

  describe "#-" do
    describe "given a Money object of the same currency" do
      it "returns a new Money with the difference of amounts" do
        (@fiveUSD - @fiveUSD).should == Money.new(0, 'USD')
      end
    end
  end

  describe "#/" do
    describe "given a Fixnum" do
      it "returns a Money with its amount divided by the argument" do
        (@fiveUSD / 5).should == Money.new(1, 'USD')
      end
    end

    describe "given a Float" do
      it "returns a Money with its amount divided by the argument" do
        (@fiveUSD / 2.0).should == Money.new(2.5, 'USD')
      end
    end

    describe "given a Money in the same currency" do
      it "returns a BigDecimal representing the ratio of the Moneys" do
        (@fiveUSD / @fiveUSD).should == 1.to_d
      end
    end

    describe "given a Money in a different currency" do
      it "raises an ArgumentError" do
        lambda { @fiveUSD / Money.new(1, "GBP") }.should raise_error(ArgumentError)
      end
    end

    describe "given nil" do
      it "raises an ArgumentError" do
        lambda { @fiveUSD / nil }.should raise_error(ArgumentError)
      end
    end
  end

  describe "#*" do
    describe "given a Fixnum" do
      it "returns a Money with its amount multiplied by the argument" do
        (@fiveUSD * 5).should == Money.new(25, 'USD')
      end
    end

    describe "given a Float" do
      it "returns a Money with its amount multiplied by the argument" do
        (@fiveUSD * 2.0).should == Money.new(10, 'USD')
      end
    end

    describe "given nil" do
      it "raises an ArgumentError" do
        lambda { @fiveUSD * nil }.should raise_error(ArgumentError)
      end
    end
  end

  describe "#**" do
    describe "given a Fixnum" do
      it "returns a Money with its amount multiplied by the argument" do
        (@fiveUSD ** 2).should == Money.new(25, 'USD')
      end
    end

    describe "given a Float" do
      it "returns a Money with its amount multiplied by the argument" do
        (@fiveUSD ** 3.0).should == Money.new(125, 'USD')
      end
    end

    describe "given nil" do
      it "raises an ArgumentError" do
        lambda { @fiveUSD ** nil }.should raise_error(ArgumentError)
      end
    end
  end

  describe "#abs" do
    it "returns a Money with the absolute value of the amount" do
      @fiveUSD.abs.should == @fiveUSD
      @minusOneUSD.abs.should == -@minusOneUSD
    end
  end

  describe "#zero?" do
    describe "when the Money has no value" do
      it "is true" do
        Money.new(0, 'USD').should be_zero
      end
    end

    describe "when the Money has value" do
      it "is false" do
        Money.new(3, 'GBP').should_not be_zero
      end
    end
  end
end
