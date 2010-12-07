require 'spec_helper'

shared_examples_for "a scenario where the job should be updated" do
  it "should update the job" do
    SsuJob.should_receive(:find_by_job_guid).with("123abc").and_return(@job)
    @job.should_receive(:update_attributes).with(:status => "401", :result => "auth.badcreds")

    put :update,
      :id => "123abc",
      :status => "401",
      :result => "auth.badcreds",
      :timestamp => 5.seconds.ago
  end
end

describe SsuJobsController do
  describe "POST /credentials/1/jobs" do
    it_should_behave_like "it has a logged-in user"

    describe "with an invalid account credential" do
      before do
        @current_user.stub!(:account_key).and_return('abcde')
        AccountCred.delete_all
      end

      it "returns a 404" do
        post :create
        response.should be_missing
      end
    end

    describe "with a valid account credential" do
      before do
        @job = stub_model(SsuJob, :jobid => "abcde")
        SsuJob.stub!(:start).and_return(@job)
        @account_cred = mock_model(AccountCred)

        controller.stub!(:find_account_cred)
        controller.instance_variable_set("@account_cred", @account_cred)
      end

      describe "where the last job was denied" do
        it "renders an error" do
          SsuJob.stub!(:start).and_return(nil)
          @account_cred.stub!(:last_job).and_return(@job)
          @job.stub!(:status).and_return(401)

          post :create
          response.should render_template(:create_error_denied)
        end
      end

      it "sets the @job ivar to a presenter" do
        post :create
        assigns[:job].should be_an_instance_of(SsuJobPresenter)
        assigns[:job].job.should == @job
      end

      it "sets the @account_cred ivar" do
        post :create
        assigns[:account_cred].should == @account_cred
      end

      describe "without a format" do
        it "redirects to the accounts list" do
          post :create
          response.should redirect_to(root_url)
        end
      end

      describe "wanting a non-HTML format" do
        it "renders a template" do
          post :create, :format => 'xml'
          response.should render_template(:show)
        end
      end
    end
  end
end
