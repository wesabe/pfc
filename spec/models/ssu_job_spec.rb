require 'spec_helper'

describe SsuJob do
  it_should_behave_like "it has a logged-in user"

  before do
    @now = Time.now
    @account_key = UID.generate
    @cred = AccountCred.make(:user => current_user)
    @accounts = []
    3.times { @accounts << Account.make(:user => current_user, :account_cred => @cred) }
    @ssu_job = SsuJob.make(:started, :user => current_user, :account_cred => @cred)
    @ssu_job.should be_valid
  end

  it "cannot convert itself to JSON" do
    lambda { @ssu_job.to_json }.should raise_error(NotImplementedError)
  end

  describe "accounts" do
    it "has an array of account for user ids" do
      @ssu_job.account_ids.should contain_same_elements_as([1,2,3])
    end

    it "has a method to return accounts" do
      @ssu_job.accounts.should contain_same_elements_as(@accounts)
    end
  end

  context "when pending" do
    before do
      @ssu_job.status = 202
    end

    it "is not complete" do
      @ssu_job.should_not be_complete
    end

    it "is not failed" do
      @ssu_job.should_not be_failed
    end

    it "is pending" do
      @ssu_job.should be_pending
    end

    it "is not successful" do
      @ssu_job.should_not be_successful
    end

    it "returns nil for succeeded_at" do
      @ssu_job.succeeded_at.should be_nil
    end
  end

  context "when successful" do
    before do
      @ssu_job.status = 200
    end

    it "is complete" do
      @ssu_job.should be_complete
    end

    it "is not failed" do
      @ssu_job.should_not be_failed
    end

    it "is not pending" do
      @ssu_job.should_not be_pending
    end

    it "is successful" do
      @ssu_job.should be_successful
    end

    it "returns the last updated timestamp for succeeded_at" do
      @ssu_job.succeeded_at.should == @ssu_job.updated_at
    end
  end

  context "when failed" do
    before do
      @ssu_job.status = 500
    end

    it "is complete" do
      @ssu_job.should be_complete
    end

    it "is failed" do
      @ssu_job.should be_failed
    end

    it "is not pending" do
      @ssu_job.should_not be_pending
    end

    it "is not successful" do
      @ssu_job.should_not be_successful
    end

    it "returns nil for succeeded_at" do
      @ssu_job.succeeded_at.should be_nil
    end
  end

  describe "update_status method" do
    before do
      @params = {:status => 202, :result => "auth.user"}
    end

    it "sets the status" do
      lambda { @ssu_job.update_status(:status => 200, :result => 'ok', :version => 1) }.
        should change(@ssu_job, :status).
                 from(202).
                 to(200)
    end

    it "sets the result" do
      lambda { @ssu_job.update_status(:status => 200, :result => 'ok', :version => 1) }.
        should change(@ssu_job, :result).
                 from('started').
                 to('ok')
    end

    it "updates the accounts list" do
      @ssu_job.should_receive(:update_accounts).with(true)
      @ssu_job.update_status(:status => 200, :result => 'ok', :version => 1)
    end

    describe "when the job is already done" do
      before do
        @ssu_job.update_status(:status => 200, :result => 'ok', :version => 2)
      end

      it "does not update the result" do
        lambda do
          @ssu_job.update_status(:status => 202, :result => 'account.upload.success', :version => 1)
        end.should_not change(@ssu_job, :result)
      end

      it "does not update the status" do
        lambda do
          @ssu_job.update_status(:status => 202, :result => 'account.upload.success', :version => 1)
        end.should_not change(@ssu_job, :status)
      end
    end

    describe "when the job finishes between being read from the database and being saved to the database" do
      before do
        @ssu_job_on_another_machine = SsuJob.find(@ssu_job.id)
        @ssu_job_on_another_machine.update_status(:status => 200, :result => 'ok', :version => 2)
      end

      it "retrieves the value set by someone else" do
        lambda do
          @ssu_job.update_status(:status => 202, :result => 'account.download', :version => 1)
        end.should change(@ssu_job, :status).to(200)
      end
    end

    describe "when the database version is newer than this version" do
      before do
        @ssu_job_on_another_machine = SsuJob.find(@ssu_job.id)
        @ssu_job_on_another_machine.update_status(:status => 202, :result => 'auth.security.unknown', :version => 5)
      end

      it "retrieves the version set by someone else" do
        lambda do
          @ssu_job.update_status(:status => 202, :result => 'auth.security', :version => 4)
        end.should change(@ssu_job, :version).to(5)
      end
    end

    describe "when data is given" do
      before do
        @data = {"foo" => "bar"}
        @params[:data] = {"auth.user" => @data}.to_json
        @params[:version] = 1
      end

      it "sets the data attribute" do
        lambda { @ssu_job.update_status(@params) }.
          should change(@ssu_job, :data).
                   from(nil).
                   to(@data)
      end
    end

    describe "when data is blank" do
      it "does not set the data attribute" do
        lambda { @ssu_job.update_status(@params) }.
          should_not change(@ssu_job, :data).from(nil)
      end
    end
  end

  describe "class method start" do
    before do
      @guid = UID.generate
      @cred.stub!(:begin_job).with(current_user).and_return(@guid)
    end

    context "when the last job was successful" do
      before do
        @ssu_job.update_status(:status => 200, :result => 'ok', :version => @ssu_job.version+1)
      end

      it "gets a job guid" do
        lambda { SsuJob.start(current_user, @cred) }.should change { SsuJob.last.jobid }.to(@guid)
      end

      it "creates a job" do
        lambda { SsuJob.start(current_user, @cred) }.should change(SsuJob, :count).by(1)
      end
    end

    context "when there was no previous job" do
      before do
        @ssu_job.destroy
      end

      it "creates a job" do
        lambda { SsuJob.start(current_user, @cred) }.should change(SsuJob, :count).by(1)
      end
    end

    context "when starting the job fails" do
      before do
        @cred.stub!(:begin_job).with(current_user).and_return(nil)
      end

      it "does not create a job" do
        lambda { SsuJob.start(current_user, @cred) }.should_not change(SsuJob, :count)
      end
    end

    context "when the last job is still pending" do
      before do
        # the top-level before block creates a pending job, so just check it here
        @ssu_job.should be_pending
      end

      it "does not create a job" do
        lambda { SsuJob.start(current_user, @cred).should == false }.should_not change(SsuJob, :count)
      end

      context "but expired" do
        before do
          @ssu_job.expires_at = 1.day.ago
          @ssu_job.save!
        end

        it "creates an ssu job" do
          lambda { SsuJob.start(current_user, @cred) }.should change(SsuJob, :count).by(1)
        end
      end
    end

    context "when the previous job failed auth" do
      before do
        @ssu_job.update_status(:status => SsuJob::Status::UNAUTHENTICATED, :result => 'auth.user.invalid', :version => @ssu_job.version+1)
      end

      it "does not create a job" do
        lambda { SsuJob.start(current_user, @cred).should == false }.should_not change(SsuJob, :count)
      end
    end

    context "when the previous job failed for denied access" do
      before do
        @ssu_job.update_status(:status => SsuJob::Status::UNAUTHORIZED, :result => 'auth.noaccess', :version => @ssu_job.version+1)
      end

      it "does not create a job" do
        lambda { SsuJob.start(current_user, @cred).should == false }.should_not change(SsuJob, :count)
      end
    end
  end
end