require 'spec_helper'

describe Money::Bag do
  before do
    @bag = Money::Bag.new
    @fiveUSD = Money.new(5, 'USD')
    @oneGBP = Money.new(1, 'GBP')
    clear_currency_exchange_rates
    CurrencyExchangeRate.make(:currency => 'GBP', :rate => 0.5, :date => Date.today)
    CurrencyExchangeRate.make(:currency => 'JPY', :rate => 1000, :date => Date.today)
  end

  it "is mixed" do
    @bag.should be_mixed
  end

  describe "#+" do
    describe "when given a Money" do
      before do
        @newbag = @bag + @fiveUSD
      end

      it "returns a Money::Bag with the Money included" do
        @newbag['USD'].should == @fiveUSD
      end
    end

    describe "when given a Money::Bag" do
      before do
        @bag1 = @bag + @oneGBP
        @bag2 = @bag + @fiveUSD
        @newbag = @bag1 + @bag2
      end

      it "returns a Money::Bag with all Moneys included" do
        @newbag.currencies.should == ['GBP', 'USD']
        @newbag['GBP'].should == @oneGBP
        @newbag['USD'].should == @fiveUSD
      end
    end
  end

  describe "#-" do
    describe "given itself" do
      before do
        @bag = (@bag + @fiveUSD) - (@bag + @fiveUSD)
      end

      it "returns a Money::Bag with zero value" do
        @bag.convert_to_currency('USD').should be_zero
      end
    end

    describe "given a Money::Bag with different amounts" do
      before do
        @bag = (@bag + @fiveUSD) - (@bag + @oneGBP)
      end

      it "returns a Money::Bag with the LHS amount unchanged" do
        @bag['USD'].should == @fiveUSD
      end

      it "returns a Money::Bag with the RHS amount negated" do
        @bag['GBP'].should == -@oneGBP
      end
    end
  end

  describe "#*" do
    describe "given a Fixnum" do
      before do
        @bag = (@fiveUSD + @oneGBP) * 2
      end

      it "returns a new Money::Bag with all Moneys multiplied by the argument" do
        @bag.should == Money.new(10, 'USD') + Money.new(2, 'GBP')
      end
    end

    describe "given a Float" do
      before do
        @bag = (@fiveUSD + @oneGBP) * 2.0
      end

      it "returns a new Money::Bag with all Moneys multiplied by the argument" do
        @bag.should == Money.new(10, 'USD') + Money.new(2, 'GBP')
      end
    end
  end

  describe "#**" do
    describe "given a Fixnum" do
      before do
        @bag = (@fiveUSD + @oneGBP) ** 2
      end

      it "returns a new Money::Bag with all Moneys raised to the argument" do
        @bag.should == Money.new(25, 'USD') + Money.new(1, 'GBP')
      end
    end
  end

  describe "#/" do
    describe "given a Fixnum" do
      before do
        @bag = (@fiveUSD + @oneGBP) / 2
      end

      it "returns a new Money::Bag with all Moneys divided by the argument" do
        @bag.should == Money.new(2.5, 'USD') + Money.new(0.5, 'GBP')
      end
    end

    describe "given a Float" do
      before do
        @bag = (@fiveUSD + @oneGBP) / 2.0
      end

      it "returns a new Money::Bag with all Moneys multiplied by the argument" do
        @bag.should == Money.new(2.5, 'USD') + Money.new(0.5, 'GBP')
      end
    end
  end

  describe "#abs" do
    describe "with positive Moneys" do
      before do
        @bag.add(@fiveUSD)
      end

      it "returns a Money::Bag equal to itself" do
        @bag.abs.should == @bag
      end
    end

    describe "with negative Moneys" do
      before do
        @bag.add(-@fiveUSD)
      end

      it "returns a Money::Bag equal to the negation of itself" do
        @bag.abs.should == -@bag
      end
    end

    describe "with mixed positive and negative Moneys" do
      before do
        @bag.add(@fiveUSD)
        @bag.add(-@oneGBP)
      end

      it "returns a Money::Bag containing the absolute value of all contained Moneys" do
        @bag.abs.should == Money::Bag.new.add(@fiveUSD).add(@oneGBP)
      end
    end
  end

  describe "with no money" do
    it "returns the zero Money when accessing any currency" do
      @bag['USD'].should be_zero
    end

    it "has no currencies" do
      @bag.currencies.should be_empty
    end

    it "converts to zero in any currency" do
      @bag.convert_to_currency('EUR').should == Money.zero('EUR')
    end

    it "returns itself when dividing" do
      (@bag / 2).should == @bag
    end

    it "returns itself when multiplying" do
      (@bag * 2).should == @bag
    end

    it "returns itself when added to itself" do
      (@bag + @bag).should == @bag
    end

    it "returns itself when subtracted from itself" do
      (@bag - @bag).should == @bag
    end

    describe "#to_s" do
      describe "given a currency" do
        it "formats zero according to that currency" do
          @bag.to_s(:currency => 'USD').should == "$0.00"
        end
      end

      describe "not given a currency" do
        it "returns 0" do
          @bag.to_s.should == '0'
        end
      end
    end
  end

  describe "with one Money" do
    before do
      @bag.add(@fiveUSD)
    end

    it "returns that Money when accessing its currency" do
      @bag['USD'].should == @fiveUSD
    end

    it "has one currency" do
      @bag.currencies.should == ['USD']
    end

    it "adds to an existing Money of the same currency" do
      @bag.add(@fiveUSD)
      @bag['USD'].should == @fiveUSD + @fiveUSD
    end

    it "converts to the Money's currency as itself" do
      @bag.convert_to_currency('USD').should == @fiveUSD
    end

    describe "#to_s" do
      describe "given a currency" do
        it "formats itself according to that currency" do
          @bag.to_s(:currency => 'USD').should == "$5.00"
          @bag.to_s(:currency => 'GBP').should == "£2.50"
        end
      end

      describe "given no currency" do
        it "formats itself according to the currency of the one Money" do
          @bag.to_s.should == "$5.00"
        end
      end
    end
  end

  describe "with many Moneys" do
    before do
      @bag.add(@oneGBP)
      @bag.add(@fiveUSD)
    end

    it "returns each Money separately when accessing them by currency" do
      @bag['USD'].should == @fiveUSD
      @bag['GBP'].should == @oneGBP
    end

    it "has many currencies, sorted by name" do
      @bag.currencies.should == ['GBP', 'USD']
    end

    it "adds to an existing Money of the same currency" do
      @bag.add(@fiveUSD)
      @bag['USD'].should == @fiveUSD + @fiveUSD
    end

    it "converts to any currency by summing the converted amounts" do
      @bag.convert_to_currency('USD').should == Money.new(7, 'USD')
      @bag.convert_to_currency('GBP').should == Money.new(3.5, 'GBP')
      @bag.convert_to_currency('JPY').should == Money.new(7000, 'JPY')
    end

    describe "#to_s" do
      describe "given a currency" do
        it "formats itself according to that currency" do
          @bag.to_s(:currency => 'USD').should == "$7.00"
          @bag.to_s(:currency => 'GBP').should == "£3.50"
        end
      end

      describe "not given a currency" do
        it "returns 0" do
          @bag.to_s.should == '0'
        end
      end
    end
  end
end
