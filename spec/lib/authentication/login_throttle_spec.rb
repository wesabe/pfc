require 'spec_helper'

describe Authentication::LoginThrottle do
  before do
    Time.stub!(:now).and_return(Time.mktime(2009, 1, 8, 17, 4))
    @user = stub(:user, :id => 200, :username => "Bob")
    @throttle = Authentication::LoginThrottle.new(@user)
  end

  describe "checking to see if a clean user should be denied a login attempt" do
    before do
      Rails.cache.clear
    end

    it "allows an attempted login" do
      assert @throttle.allow_login?
    end
  end

  describe "checking to see if a throttled user should be denied a login attempt" do
    before do
      Rails.cache.write('throttle:200', 120.seconds.from_now)
    end

    it "denies an attempted login" do
      @throttle.allow_login?.should_not be(true)
    end

    context "raising a throttle error" do
      it "should raise an error containing a retry-after value" do
        lambda { @throttle.raise_throttle_error }.should
          raise_error(Authentication::LoginThrottle::UserThrottleError) {|e| e.retry_after.should == 120 }
      end
    end
  end

  describe "registering a failed login attempt on a clean user" do
    before do
      Rails.cache.clear
    end

    it "doesn't set a throttle key in the cache" do
      lambda { @throttle.failed_login! }.
        should_not change { Rails.cache.exist?('throttle:200') }
    end

    it "increments the login attempt counter in the cache" do
      lambda { @throttle.failed_login! }.
        should change { Rails.cache.read('badlogins:200') }.
                from(nil).
                to(1)
    end
  end

  describe "registering a failed login attempt on a user with 6 failed logins" do
    before do
      Rails.cache.write("badlogins:200", 6)
    end

    it "sets a 15-second throttle key in memcached" do
      @throttle.failed_login!
      Rails.cache.read("throttle:200").should be_close(15.seconds.from_now, 1.second)
    end

    it "increments the login attempt counter in memcached" do
      lambda { @throttle.failed_login! }.
        should change { Rails.cache.read('badlogins:200') }.
                from(6).
                to(7)
    end
  end

  describe "registering a failed login attempt on a user with 7 failed logins" do
    before do
      Rails.cache.stub!(:write).and_return("NOT_STORED\n")
      Rails.cache.stub!(:increment).and_return(7)
    end

    it "sets a 30-second throttle key in memcached" do
      Rails.cache.should_receive(:write).with("throttle:200", 30.seconds.from_now, :expires_in => 30.seconds)
      @throttle.failed_login!
    end
  end

  describe "registering a failed login attempt on a user with 8 failed logins" do
    before do
      Rails.cache.stub!(:write).and_return("NOT_STORED\n")
      Rails.cache.stub!(:increment).and_return(8)
    end

    it "sets a 60-second throttle key in memcached" do
      Rails.cache.should_receive(:write).with("throttle:200", 60.seconds.from_now, :expires_in => 60.seconds)
      @throttle.failed_login!
    end
  end

  describe "registering a successful login by a user" do
    before do
      Rails.cache.stub!(:delete).and_return(nil)
    end

    it "deletes the throttle key from memcached" do
      Rails.cache.should_receive(:delete).with("throttle:200").and_return(nil)
      @throttle.successful_login!
    end

    it "deletes the login attempt counter from memcached" do
      Rails.cache.should_receive(:delete).with("badlogins:200").and_return(nil)
      @throttle.successful_login!
    end
  end
end