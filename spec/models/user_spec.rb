require 'spec_helper'
require 'date'
require 'fileutils'
require 'rational'

describe User do
  before do
    @valid_password = 'blah'
    @invalid_password = 'h4x0r'
    @user = described_class.make(:password => @valid_password, :password_confirmation => @valid_password)
    @throttle = stub(:throttle,
      :allow_login? => true,
      :successful_login! => true,
      :failed_login! => true,
      :raise_throttle_error => nil
    )
    Authentication::LoginThrottle.stub!(:new).and_return(@throttle)
  end

  after do
    @user.delete rescue nil
  end

  describe "checking a password's validity" do
    it "is valid when a hash of the candidate and the salt match the stored hash" do
      @user.valid_password?(@valid_password).should be(true)
    end

    it "is invalid when a hash of the candidate and the salt does not match the stored hash" do
      @user.valid_password?(@invalid_password).should be(false)
    end
  end

  describe "authenticating a valid username and password" do
    it "checks to see if the user account is throttled" do
      @throttle.should_receive(:allow_login?).and_return(true)
      described_class.authenticate(@user.username, @valid_password)
    end

    it "registers a successful login for that user" do
      @throttle.should_receive(:successful_login!).and_return(true)
      described_class.authenticate(@user.username, @valid_password)
    end

    it "returns the user" do
      described_class.authenticate(@user.username, @valid_password).should == @user
    end
  end

  describe "authenticating an invalid username" do
    it "returns nil" do
      described_class.authenticate("notrealusername", @valid_password).should be_nil
    end
  end

  describe "authenticating an invalid password" do
    it "checks to see if the user account is throttled" do
      @throttle.should_receive(:allow_login?).and_return(true)
      described_class.authenticate(@user.username, "floppity")
    end

    it "registers a failed login for that user" do
      @throttle.should_receive(:failed_login!).and_return(true)
      described_class.authenticate(@user.username, "floppity")
    end

    it "returns nil" do
      described_class.authenticate(@user.username, "floppity").should be_nil
    end
  end

  describe "authenticating a throttled user" do
    before do
      @throttle = stub(:throttle, :allow_login? => false, :failed_login! => true, :raise_throttle_error => nil)
      Authentication::LoginThrottle.stub!(:new).and_return(@throttle)
      @throttle.stub!(:allow_login? => false, :failed_login! => true, :raise_throttle_error => nil)
    end

    it "checks to see if the user account is throttled" do
      @throttle.should_receive(:allow_login?).and_return(false)
      described_class.authenticate(@user.username, "floppity")
    end

    it "registers a failed login for that user" do
      @throttle.should_receive(:failed_login!).and_return(true)
      described_class.authenticate(@user.username, "floppity")
    end

    it "raises an exception" do
      @throttle.should_receive(:raise_throttle_error)
      described_class.authenticate(@user.username, "floppity")
    end
  end

  describe "with a blank username" do
    it "should not be locatable by username" do
      described_class.find_with_normalized_name("").should be_nil
    end
  end
end

describe "User: a new user" do
  before do
    @user = User.make
  end

  it "should not be valid without a username or email address" do
    @user.username = @user.email = nil
    @user.should have(1).error_on(:username)
  end

  it "should not be valid without an email address" do
    @user.email = nil
    @user.should have_at_least(1).error_on(:email)
  end

  it "should not be valid with an invalid email address" do
    invalid_addresses = ["bob", "bob@gmail", "bobgmail.com", "123 Bob Drive", "x@y.z"]
    invalid_addresses.each do |email|
      @user.email = email
      @user.should_not be_valid
    end
  end

  it "should be valid with an valid email address" do
    valid_addresses = ["bob@gmail.com", "bob+foo@gmail.com", "bob@gmail.co.uk"] # others?
    valid_addresses.each do |email|
      @user.email = email
      @user.should be_valid
    end
  end

  it "should not be valid with an unknown currency" do
    @user.default_currency = "DINGO"
    @user.should_not be_valid
    @user.default_currency = "EUR"
    @user.should be_valid
  end
end

describe User, "creating a User" do
  before do
    described_class.delete_all

    @gbp = Currency.new('GBP')
    @usd = Currency.new('USD')
    @uk = Country.make(:code => 'uk', :currency => 'GBP')
    @us = Country.make(:code => 'us', :currency => 'USD')
    @user = described_class.new(:username => "foo", :password => "foo", :email => "foo@bar.baz", :country => @uk)
  end

  it "should set the default currency to the country's currency" do
    @user.default_currency.should == @usd # default
    @user.save!
    @user.default_currency.should == @gbp
  end

  describe "when the user's currency is already set" do
    before do
      @user.default_currency = 'USD'
      @user.country = @uk
    end

    it "should not set the default currency to the country's currency" do
      lambda { @user.save! }.
        should_not change(@user, :default_currency).from(Currency.new('USD'))
    end
  end

  it "should allow a default currency to be set with a Currency instance" do
    @user.default_currency = @usd
    @user.save!
    @user.reload
    @user.default_currency.should == @usd
  end

  it "should generate a normalized name" do
    @user.name = "Foo Bar"
    @user.save!
    @user.normalized_name.should == "foobar"
  end
end

describe User, "with no name" do
  before do
    @user = described_class.new(:name => '')
  end

  it "has Anonymous as the display name" do
    @user.display_name.should == 'Anonymous'
  end

  it "is anonymous" do
    @user.should be_anonymous
  end
end

describe User, "with an anonymized name" do
  before do
    @user = described_class.new(:name => "Anonymous abcde")
  end

  it "is anonymous" do
    @user.should be_anonymous
  end
end

describe User, "with a regular name" do
  before do
    @user = described_class.new(:name => "John Doe")
  end

  it "is not anonymous" do
    @user.should_not be_anonymous
  end
end

describe User, "change_password! method" do
  before do
    described_class.delete_all

    @user = described_class.make
    @newpass = 'monkeys!'

    @old_account_key = @user.account_key
    @new_account_key = User.generate_account_key(@user.uid, @newpass)

    @sourcedir = Upload.statement_dir(@old_account_key)
    @targetdir = Upload.statement_dir(@new_account_key)

    # ensure directories exist as required
    FileUtils.mkdir_p(@sourcedir)
    FileUtils.rm_rf(@targetdir)

    # and let's add a file to track movement
    @source_tracker = @sourcedir+'tracker.txt'
    @target_tracker = @targetdir+'tracker.txt'
    @source_tracker.open('w') {|f| f.puts "FOUND YOU" }
  end

  it "sets the password to the new password" do
    lambda { @user.change_password!(@newpass) }.
      should change(@user, :password).to(@newpass)
  end

  it "sets the password_confirmation to the new password" do
    lambda { @user.change_password!(@newpass) }.
      should change(@user, :password_confirmation).to(@newpass)
  end

  it "updates the old accounts with the new account key" do
    described_class.stub!(:generate_account_key).and_return(@new_account_key)
    lambda { @user.change_password!(@newpass) }.
      should_not change { @user.reload.accounts }
  end

  it "updates the old account credentials with the new account key" do
    described_class.stub!(:generate_account_key).and_return(@new_account_key)
    lambda { @user.change_password!(@newpass) }.
      should_not change { @user.reload.account_creds }
  end
end

describe User, "find by username or email" do
  before do
    described_class.delete_all

    @old_user = described_class.make(:last_web_login => 1.year.ago)
    @user     = described_class.make(:last_web_login => 1.day.ago)

    described_class.update_all :email => 'ww@example.com' # sneak past the uniqueness validator

    @user.reload; @old_user.reload
  end

  it "should find users by username" do
    described_class.find_by_username_or_email(@user.username).should == @user
  end

  it "should find most recently logged-in account by email" do
    described_class.find_by_username_or_email(@user.email).should == @user
  end
end

describe User, "local time" do
  before do
    @server_offset = Time.now.utc_offset / 60
    @user = described_class.make
    @user.timezone_offset = @server_offset + 180
  end

  it "should return the current time adjusted to the user's time zone" do
    @user.local_time.offset.should == Rational(@user.timezone_offset, 1440)
  end

  it "should return the local time if no timezone offset is set" do
    @user.timezone_offset = nil
    @user.local_time.offset.should == Rational(@server_offset, 1440)
  end

end

describe User, "updating the name" do
  before do
    @user = described_class.make(:name => "Bob Barker")
  end

  it "should update the normalized name when the name is changed" do
    @user.normalized_name.should == 'bobbarker'
    @user.name = "Bob Bob"
    @user.save
    @user.normalized_name.should == 'bobbob'
  end
end