require 'spec_helper'

if defined?(OFX_CONVERTER) && File.executable?(OFX_CONVERTER.split(/\s/).first)
  describe Importer do
    #it_should_behave_like "it has a logged-in user"

    before(:each) do
      @user = mock_model(User, :default_currency => Currency.new, :account_key => 'abcdefg')
      @user.stub!(:account_key=).and_return(@user.account_key)
      @user.stub!(:update_attribute)
      @fi = mock_model(FinancialInst, :name => "Some Bank", :wesabe_id => "us-001435", :mapped_to_id => nil, :date_format_ddmmyyyy? => false)
      User.stub!(:find).and_return(@user)
      FinancialInst.stub!(:find_by_wesabe_id).and_return(@fi)
      FinancialInst.stub!(:find).and_return(@fi)
    end

    it "should generate an upload from a QIF post" do
      data = File.read(File.dirname(__FILE__) + '/../fixtures/things/raw_post.qif')
      upload = Importer.generate_upload_from_raw_post(@user, data)
      upload.balance.should == 1000
      upload.account_number.should == '1234'
      upload.account_type.should == 'Checking'
      upload.fi_wesabe_id.should == @fi.wesabe_id
    end
  end
else
  print "(ofx converter not installed -- skipping specs)"
end

describe Importer, "fix_line_endings_method" do
  it "should convert Mac line endings to Unix" do
    Importer.fix_line_endings("foo bar\r\rbaz\r\r").should == "foo bar\nbaz\n"
  end

  it "should convert Windows line endings to Unix" do
    Importer.fix_line_endings("foo bar\r\nbaz\r\n").should == "foo bar\nbaz\n"
  end

  it "should not change Unix line endings" do
    Importer.fix_line_endings("foo bar\n\nbaz\n").should == "foo bar\n\nbaz\n"
  end
end