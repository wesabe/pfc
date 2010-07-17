require 'spec_helper'

describe Tagging do
  before do
    @tagging = Tagging.make
  end

  context 'a tagging with a single word name' do
    before do
      @tagging.name = 'chinese'
    end

    it "does not surround tag names without spaces in quotes" do
      @tagging.display_name.should == 'chinese'
    end

    it "shows the split amount after the tag name" do
      @tagging.split_amount = 5
      @tagging.display_name.should == "chinese:5"
    end
  end

  context 'a tagging with a multiple word name' do
    before do
      @tagging.name = 'good eats'
    end

    it "surrounds tag names with spaces in quotes" do
      @tagging.display_name.should == '"good eats"'
    end
  end

  context 'a tagging split with a fractional part' do
    before do
      @tagging.split_amount = 4.5
    end

    it "displays the decimal part of the split value" do
      @tagging.split_amount_display.should == '4.50'
    end
  end

  context 'a tagging split with no fractional part' do
    before do
      @tagging.split_amount = 5
    end

    it "should not display the decimal part of the split value when not required" do
      @tagging.split_amount_display.should == '5'
    end
  end
end

describe Tagging, "to_param" do
  it "escapes characters using Tag::OUTGOING_URL_ESCAPES" do
    Tag::OUTGOING_URL_ESCAPES.each do |o, s|
      Tagging.new(:name => o).to_param.should == s
    end
  end
end