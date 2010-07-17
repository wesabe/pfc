require 'spec_helper'

describe Authentication::LoginThrottle do
  before(:each) do
    Time.stub!(:now).and_return(Time.mktime(2009, 1, 8, 17, 4))
    @user = stub(:user, :id => 200, :username => "Bob")
    @throttle = Authentication::LoginThrottle.new(@user)
  end

  describe "checking to see if a clean user should be denied a login attempt" do
    before(:each) do
      CACHE.stub!(:[]).and_return(nil)
    end

    it "checks for the existence of a throttle key in memcached" do
      CACHE.should_receive(:[]).with("throttle:200").and_return(nil)
      @throttle.allow_login?
    end

    it "allows an attempted login" do
      @throttle.allow_login?.should be(true)
    end
  end

  describe "checking to see if a throttled user should be denied a login attempt" do
    before(:each) do
      CACHE.stub!(:[]).and_return(120.seconds.from_now)
    end

    it "checks for the existence of a throttle key in memcached" do
      CACHE.should_receive(:[]).with("throttle:200").and_return(120)
      @throttle.allow_login?
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
    before(:each) do
      CACHE.stub!(:add).and_return("STORED\n")
      CACHE.stub!(:incr).and_return(1)
    end

    it "doesn't set a throttle key in memcached" do
      CACHE.should_not_receive(:set).with("throttle:200", "active", anything)
      @throttle.failed_login!
    end

    it "ensures the existence of a login attempt counter in memcached" do
      CACHE.should_receive(:add).with("badlogins:200", "0", 1.day, true)
      @throttle.failed_login!
    end

    it "increments the login attempt counter in memcached" do
      CACHE.should_receive(:incr).with("badlogins:200").and_return(1)
      @throttle.failed_login!
    end
  end

  describe "registering a failed login attempt on a user with 6 failed logins" do
    before(:each) do
      CACHE.stub!(:add).and_return("NOT_STORED\n")
      CACHE.stub!(:incr).and_return(6)
    end

    it "sets a 15-second throttle key in memcached" do
      CACHE.should_receive(:set).with("throttle:200", 15.seconds.from_now, 15.seconds)
      @throttle.failed_login!
    end

    it "ensures the existence of a login attempt counter in memcached" do
      CACHE.should_receive(:add).with("badlogins:200", "0", 1.day, true)
      @throttle.failed_login!
    end

    it "increments the login attempt counter in memcached" do
      CACHE.should_receive(:incr).with("badlogins:200").and_return(4)
      @throttle.failed_login!
    end
  end

  describe "registering a failed login attempt on a user with 7 failed logins" do
    before(:each) do
      CACHE.stub!(:add).and_return("NOT_STORED\n")
      CACHE.stub!(:incr).and_return(7)
    end

    it "sets a 30-second throttle key in memcached" do
      CACHE.should_receive(:set).with("throttle:200", 30.seconds.from_now, 30.seconds)
      @throttle.failed_login!
    end
  end

  describe "registering a failed login attempt on a user with 8 failed logins" do
    before(:each) do
      CACHE.stub!(:add).and_return("NOT_STORED\n")
      CACHE.stub!(:incr).and_return(8)
    end

    it "sets a 60-second throttle key in memcached" do
      CACHE.should_receive(:set).with("throttle:200", 60.seconds.from_now, 60.seconds)
      @throttle.failed_login!
    end
  end

  describe "registering a successful login by a user" do
    before(:each) do
      CACHE.stub!(:delete).and_return(nil)
    end

    it "deletes the throttle key from memcached" do
      CACHE.should_receive(:delete).with("throttle:200").and_return(nil)
      @throttle.successful_login!
    end

    it "deletes the login attempt counter from memcached" do
      CACHE.should_receive(:delete).with("badlogins:200").and_return(nil)
      @throttle.successful_login!
    end
  end
end
