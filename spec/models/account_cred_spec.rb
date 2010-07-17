require 'spec_helper'

describe AccountCred do
  def ssu_uri(path)
    (URI.parse(SSU_INTERNAL_URI)+path).to_s
  end

  before do
    @account_cred = described_class.make
    @account_cred.should be_valid
    @account_cred.stub!(:delete_cred_from_ssu_service)
  end

  it "only allows one AccountCred per cred guid" do
    @account_cred.save
    @second_cred = AccountCred.new(@account_cred.attributes)
    @second_cred.should have_error_on(:cred_guid, :taken)
    @account_cred.stub!(:delete_cred_from_ssu_service)
    @account_cred.destroy
  end

  it "is successful if the last job succeeded" do
    # when
    @account_cred.stub!(:last_ssu_job).and_return(mock(:job, :successful? => true))

    # then
    @account_cred.should be_successful
  end

  it "is failed if the last job failed" do
    # when
    @account_cred.stub!(:last_ssu_job).and_return(mock(:job, :failed? => true))

    # then
    @account_cred.should be_failed
  end

  describe "destroyable_by? method" do
    before(:each) do
      @user = User.make
    end

    it "should be true for admins" do
      @user.stub!(:admin?).and_return(true)
      @account_cred.should be_destroyable_by(@user)
    end

    it "should be true for a user with the cred's account key" do
      @account_cred.user = @user
      @account_cred.should be_destroyable_by(@user)
    end

    it "should not be destroyable by other users" do
      @account_cred.should_not be_destroyable_by(@user)
    end
  end

  describe "to_json" do
    it "does not fail if there is no last ssu job" do
      lambda { @account_cred.to_json }.should_not raise_error
    end
  end

  describe "on being destroyed, callbacks" do
    before do
      @account_cred.save
      @account = Account.make(:account_cred => @account_cred)
      @account.should_not be_new_record
      @account_cred.accounts.should == [@account]
    end

    it "should delete its disabled accounts from the database" do
      @account.update_attribute(:status, Constants::Status::DISABLED)
      @account_cred.destroy
      lambda { @account.reload }.should raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "method begin_job" do
    before do
      @job_guid = "f01d09f4-d3dd-11dc-d7aa-b547d0f7d971"

      @user = mock_model(User, :account_key => 111, :id => 1)
      @fi   = mock_model(FinancialInst, :wesabe_id => "us-001")
      @account_cred.financial_inst = @fi

      stub_request(:post, ssu_uri('/jobs')).
        to_return(:body => @job_guid)
    end

    it "should post to the SSU server to start a new job" do
      stub_request(:post, ssu_uri('/jobs')).
        with(:user_id => @user.id, :credguid => @account_cred.cred_guid,
             :credkey => @account_cred.cred_key,:fid => @fi.wesabe_id).
        to_return(:body => @job_guid)

      @account_cred.begin_job(@user)
    end

    it "should mark the accounts as having failed if ssu is unreachable or won't talk to us" do
      stub_request(:post, ssu_uri('/jobs')).
        to_return(:body => @job_guid, :status => 401)

      @account_cred.begin_job(@user).should be_nil
    end

    it "should return the job guid from the SSU server" do
      @account_cred.begin_job(@user).should == @job_guid
    end

    it "should mark each of the accounts as pending" do
      @account_cred.begin_job(@user).should == @job_guid
    end

    it "should not accept responses that are not in valid guid format" do
      stub_request(:post, ssu_uri('/jobs')).
        to_return(:body => "<!DOCTYPE HTML PUBLIC \"-//IETF//DTD HTML 2.0//EN\">")

      @account_cred.begin_job(@user).should be_nil
    end
  end

  describe "on being destroyed, pfc" do
    it "posts to ssu service to destroy corresponding ssu_cred" do
      stub_request(:delete, ssu_uri("/creds/#{@account_cred.cred_guid}")).
        to_return(:body => '')

      @account_cred.save
      @account_cred.should_not be_new_record
      @account_cred.destroy
    end

    it "should still delete itself if ssu service returns a 404" do
      stub_request(:delete, ssu_uri("/creds/#{@account_cred.cred_guid}")).
        to_return(:body => '', :status => 404)

      @account_cred.save
      @account_cred.should_not be_new_record
      @account_cred.destroy
    end
  end


  describe "accounts" do
    before do
      @account_cred = described_class.make
      @account = Account.make(:account_cred => @account_cred)
    end

    it "should be findable via a method" do
      @account_cred.accounts.should == [@account]
    end

    it "should provide an array of account ids via a method" do
      @account_cred.account_ids_for_user.should == [@account.id_for_user]
    end
  end

  describe "ssu jobs" do
    before do
      @account_cred = described_class.make
      @account_cred.stub!(:delete_cred_from_ssu_service)
      @ssu_job = SsuJob.create!(
        :expires_at => 1.hour.from_now,
        :account_cred_id => @account_cred.id,
        :account_key => "1",
        :job_guid => "a",
        :status => 202,
        :result => "resume" )
    end

    it "should have a finder method" do
      @account_cred.ssu_jobs.should == [@ssu_job]
    end

    it "should delete associated ssu_jobs when cred is deleted" do
      @account_cred.destroy
      SsuJob.find_by_id(@ssu_job.id).should be_nil
    end

    it "should provide a finder method for the last ssu job" do
      @account_cred.last_ssu_job.should == @ssu_job
    end
  end
end