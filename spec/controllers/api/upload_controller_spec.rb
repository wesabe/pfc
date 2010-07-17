require 'spec_helper'

describe Api::UploadController, "authentication" do
  before do
    @user = User.make
    @job  = mock_model(SsuJob)

    @job.stub!(:account_key)
    @job.stub!(:account_cred_id).and_return(42)
  end

  describe "with basic auth" do
    before do
      http_login 'quentin', 'secret'
    end

    it "should log in the user by username and password" do
      User.should_receive(:authenticate).with('quentin', 'secret').and_return(@user)
      Importer.should_receive(:import_request).with(@user, @request, nil)
      post :statement, :statement => 'OFXISH'
    end

    it "should do something when the Basic Auth credentials are invalid" do
      User.should_receive(:authenticate).with('quentin', 'secret').and_return(nil)
      Importer.should_receive(:import_request).never
      post :statement, :statement => 'OFXISH'
      response.code.should == "401"
      response.body.should =~ /Access denied/
    end

    it "sets User.current" do
      User.stub!(:authenticate).with('quentin', 'secret').and_return(@user)
      Importer.stub!(:import_request).with(@user, @request, nil)
      lambda {
        post :statement, :statement => 'OFXISH'
      }.should change(User, :current).from(nil).to(@user)
    end

  end

  describe "with job guid and user id" do
    before do
      SsuJob.should_receive(:find_by_job_guid).with('abcd').and_return(@job)
    end

    it "should authenticate the user by job guid and user id" do
      @job.should_receive(:expired?).and_return(false)
      @job.should_receive(:account_key).and_return('efg')
      @user.should_receive(:account_key=).with('efg')
      User.should_receive(:find_by_id).and_return(@user)
      Importer.should_receive(:import_request).with(@user, @request, @job.account_cred_id)
      post :statement, :statement => 'OFXISH', :job_guid => 'abcd', :user_id => '1'
      response.should be_success
    end

    it "sets User.current" do
      @job.should_receive(:expired?).and_return(false)
      @job.should_receive(:account_key).and_return('efg')
      @user.should_receive(:account_key=).with('efg')
      User.should_receive(:find_by_id).and_return(@user)
      Importer.should_receive(:import_request).with(@user, @request, @job.account_cred_id)
      lambda {
        post :statement, :statement => 'OFXISH', :job_guid => 'abcd', :user_id => '1'
      }.should change(User, :current).from(nil).to(@user)
    end

    it "should fail to authenticate the user given an expired job guid" do
      @job.should_receive(:expired?).and_return(true)
      Importer.should_receive(:import_request).never
      post :statement, :statement => 'OFXISH', :job_guid => 'abcd', :user_id => '1'
      response.code.should == "401"
      response.body.should =~ /Access denied/
    end

    it "should fail to authenticate the user given an invalid user id" do
      @job.should_receive(:expired?).and_return(false)
      User.should_receive(:find_by_id).and_return(nil)
      Importer.should_receive(:import_request).never
      post :statement, :statement => 'OFXISH', :job_guid => 'abcd', :user_id => '1'
      response.code.should == "401"
      response.body.should =~ /Access denied/
    end

  end

private
  # Logs in to an action using the specified username and password and user agent
  # stolen from Coda's simple_http_auth's tests
  def http_login(username, password)
    @request.env['HTTP_AUTHORIZATION'] = "Basic #{Base64.encode64(username << ':' << password)}"
  end

end