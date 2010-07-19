require 'spec_helper'

describe UploadsHelper, "help_text_for" do
  before do
    @fi = mock_model(FinancialInst)
  end

  def set_help_text(value)
    @fi.stub!(:help_text).and_return(value)
  end

  describe "when the text contains markup" do
    before do
      set_help_text "<strong>YOU FOOL</strong>"
    end

    it "returns the text as-is" do
      helper.help_text_for(@fi).should == "<strong>YOU FOOL</strong>"
    end
  end

  describe "when the text contains no markup" do
    it "bolds the first sentence" do
      set_help_text "Hi there."
      helper.help_text_for(@fi).should include("<strong>Hi there.</strong>")
    end

    it "preserves paragraphs" do
      set_help_text "Hi there.\n\nFIX IT!"
      helper.help_text_for(@fi).should == %{<strong>Hi there.</strong><br/>\n<br/>\nFIX IT!}
    end

    it "creates links from urls" do
      set_help_text "Hi there! Go to www.chase.com"
      helper.help_text_for(@fi).should == %{<strong>Hi there!</strong> Go to<a href="http://www.chase.com" target="_blank"> www.chase.com</a>}
    end
  end
end

describe UploadsHelper, "txaction_date_range" do
  it_should_behave_like "it has a logged-in user"

  before do
    helper.extend ApplicationHelper
  end

  context "when the upload has no txactions" do
    before do
      @upload = Upload.new
    end

    it "returns n/a" do
      helper.txaction_date_range(@upload).should == 'n/a'
    end
  end

  context "when the upload has a single transaction" do
    before do
      @upload = Upload.make
      Txaction.make(:upload => @upload, :date_posted => Time.local(Time.now.year, 9, 29))
    end

    it "returns the date of the transaction" do
      helper.txaction_date_range(@upload).should == "Sep 29"
    end
  end

  context "when the upload has txactions spanning multiple days" do
    before do
      @upload = Upload.make
      3.times do |n|
        Txaction.make(:upload => @upload, :date_posted => n.days.since(Time.local(Time.now.year, 9, 29)))
      end
    end

    it "returns the span of the dates" do
      helper.txaction_date_range(@upload).should == "Sep 29..Oct  1"
    end
  end
end
