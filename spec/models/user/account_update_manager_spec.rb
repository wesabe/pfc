require 'spec_helper'

describe User::AccountUpdateManager do
  before do
    @user = stub_model(User)
    @cred = stub_model(AccountCred)
    @job  = stub_model(SsuJob)
    @fi = stub_model(FinancialInst, :ssu_support? => true)
    @cred.stub!(:financial_inst).and_return(@fi)
    @controller = stub(:controller, :ssu_enabled? => true)
    @user.stub!(:account_creds).and_return([@cred])
    @aum  = User::AccountUpdateManager.new(@user, @controller)
  end

  describe "when the AccountCred has no last job" do
    before do
      @cred.stub!(:last_ssu_job).and_return(nil)
    end

    it "should update the cred" do
      @aum.should need_to_update(@cred)
    end
  end

  describe "when the AccountCred's last job was created more than 6 hours ago" do
    before do
      @cred.stub!(:last_ssu_job).and_return(@job)
      @job.stub!(:created_at).and_return(1.day.ago)
    end

    it "should update the cred" do
      @aum.should need_to_update(@cred)
    end

    describe "and SSU cannot be reached" do
      before do
        @ssu_error = SsuError.new("timeout connecting to ssu")
        SsuJob.stub!(:start).and_raise(@ssu_error)
      end

      it "should send an exception email" do
        @aum.login!
      end
    end
  end

  describe "when the AccountCred's last job was created less than 6 hours ago" do
    before do
      @cred.stub!(:last_ssu_job).and_return(@job)
      @job.stub!(:created_at).and_return(4.hours.ago)
    end

    it "should not update the cred" do
      @aum.should_not need_to_update(@cred)
    end

    describe "and the :force option is given" do
      before do
        @aum.options[:force] = true
      end

      it "should update the cred" do
        @aum.should need_to_update(@cred)
      end
    end
  end

  describe "when the AccountCred has no accounts" do
    before do
      @cred.stub!(:last_ssu_job).and_return(@job)
      @cred.stub!(:accounts).and_return([])
    end

    it "should destroy the cred" do
      @aum.should need_to_destroy(@cred)
    end

    describe "but the AccountCred's FI is not SSU-supported" do
      before do
        @fi.stub!(:ssu_support?).and_return(false)
      end

      # the rationale here is that they are testing support for the FI,
      # and that we should keep their creds around because they're useful
      it "should not destroy the cred" do
        @aum.should_not need_to_destroy(@cred)
      end
    end
  end

  describe "when the AccountCred has accounts" do
    before do
      @accounts = [stub_model(Account)]
      @cred.stub!(:last_ssu_job).and_return(@job)
      @cred.stub!(:accounts).and_return(@accounts)
    end

    it "should not destroy the cred" do
      @aum.should_not need_to_destroy(@cred)
    end
  end

  describe "when the controller is ssu enabled" do
    before do
      @controller.stub!(:ssu_enabled?).and_return(true)
    end

    it "should be ssu enabled" do
      @aum.should be_ssu_enabled
    end
  end

  describe "when the controller is not ssu enabled" do
    before do
      @controller.stub!(:ssu_enabled?).and_return(false)
    end

    it "should not be ssu enabled" do
      @aum.should_not be_ssu_enabled
    end
  end
end

module AccountUpdateManagerMatchers
  class NeedToUpdate
    def initialize(expected)
      @expected = expected
    end

    def matches?(target)
      (@target = target).update?(@expected)
    end

    def failure_message
      "expected #{@target.inspect} to want to update #{@expected.inspect}"
    end

    def negative_failure_message
      "expected #{@target.inspect} not to want to update #{@expected.inspect}"
    end
  end

  def need_to_update(cred)
    NeedToUpdate.new(cred)
  end

  class NeedToDestroy
    def initialize(expected)
      @expected = expected
    end

    def matches?(target)
      (@target = target).destroy?(@expected)
    end

    def failure_message
      "expected #{@target.inspect} to want to destroy #{@expected.inspect}"
    end

    def negative_failure_message
      "expected #{@target.inspect} not to want to destroy #{@expected.inspect}"
    end
  end

  def need_to_destroy(cred)
    NeedToDestroy.new(cred)
  end
end

Rspec.configure do |config|
  config.include AccountUpdateManagerMatchers
end
