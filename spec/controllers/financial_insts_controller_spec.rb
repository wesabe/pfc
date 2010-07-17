require 'spec_helper'

describe FinancialInstsController do
  before do
    controller.stub!(:generate_fi_stats)
  end

  describe "handling GET /financial-institutions.xml" do
    it_should_behave_like "it has a logged-in user"

    before do
      @fi = FinancialInst.make(:creating_user => current_user)
    end

    def run
      get :index, :format => "xml"
    end

    it "should find all approved and user-approved financial institutions and assign them to the view" do
      run
      assigns[:financial_insts].should == [@fi]
    end

    it "should render financial_insts/index" do
      run
      response.should render_template("financial_insts/index")
    end

  end

  describe "handling GET /financial-institutions/new" do
    it_should_behave_like "it has a logged-in user"

    before do
      current_user.stub!(:country_id).and_return(400)
      @countries = [[1, "Oceania"]]
      @fi = mock_model(FinancialInst)
      FinancialInst.stub!(:new).and_return(@fi)
      Country.stub!(:ids_and_names).and_return(@countries)
    end

    def run
      get :new, :name => "Dingo"
    end

    it "should instantiate a new FinancialInst with the given name and the current user's country and assign it to the view" do
      current_user.should_receive(:country_id).and_return(400)
      FinancialInst.should_receive(:new).with(:name => "Dingo", :country_id => 400).and_return(@fi)
      run
      assigns[:financial_inst].should == @fi
    end

    it "should select the ids and names of all countries and assign them to the view" do
      Country.should_receive(:ids_and_names).and_return(@countries)
      run
      assigns[:countries].should == @countries
    end

    it "should render financial_insts/new" do
      run
      response.should render_template("financial_insts/new")
    end

  end

  describe "handling GET /financial-institutions as an anonymous user" do
    it "redirects the user away" do
      cookies[:wesabe_member] = true
      get :index
      response.should redirect_to(login_url)
    end
  end

  describe "handling GET /financial-institutions as a member" do
    it_should_behave_like "it has a logged-in user"

    it "redirects the user away" do
      cookies[:wesabe_member] = true
      get :index
      response.should redirect_to(root_url)
    end
  end

  describe "handling GET /financial-institutions as an admin user" do
    it_should_behave_like "it has an admin user"

    it "is successful" do
      get :index
      response.should be_success
    end
  end

  describe "handling POST /financial-institutions" do
    it_should_behave_like "it has a logged-in user"

    before(:each) do
      @countries = [[1, "Oceania"]]
      @fi = mock_model(FinancialInst, :save => true, :name => "Blah", :to_param => "us-1")
      FinancialInst.stub!(:new).and_return(@fi)
      Country.stub!(:ids_and_names).and_return(@countries)
    end

    def run
      post :create, :financial_inst => { :name => "Dingo Credit Union", :country_id => "2", :homepage_url => "http://blah.com", :login_url => "evil" }
    end

    it "should instantiate a new FinancialInst with the name, country, and homepage URL from the params, and the current user's id" do
      FinancialInst.should_receive(:new).with("name" => "Dingo Credit Union", "country_id" => "2",
                                              "homepage_url" => "http://blah.com", "creating_user_id" => current_user.id,
                                              "approved" => false).and_return(@fi)
      run
    end

    it "should render financial_insts/new with errors if the FinancialInst can't be saved" do
      @fi.should_receive(:save).and_return(false)
      run
      assigns[:financial_inst].should == @fi
    end

    it "should select the ids and names of all countries and assign them to the view if the FinancialInst can't be saved" do
      @fi.should_receive(:save).and_return(false)
      Country.should_receive(:ids_and_names).and_return(@countries)
      run
      assigns[:countries].should == @countries
    end

    it "should set the session fi_name and redirect to the new manual upload page if the FinancialInst can be saved" do
      @fi.should_receive(:save).and_return(true)
      run
      response.should redirect_to(manual_upload_path(:fi => @fi.to_param))
      flash[:fi_confirmation].should == "Your financial institution has been added."
    end
  end

  describe "handling GET /financial-institutions/1" do
    it_should_behave_like "it has an admin user"

    before(:each) do
      @fi = mock_model(FinancialInst)
      FinancialInst.stub!(:find_for_user).and_return(@fi)
    end

    def run
      get :show, :id => "1"
    end

    it "should find the financial institution and assign it to the view" do
      FinancialInst.should_receive(:find_for_user).with("1", current_user).and_return(@fi)
      run
      assigns[:financial_inst].should == @fi
    end

    it "should render financial_insts/show" do
      run
      response.should render_template("financial_insts/show")
    end

    it "should raise a 404 if the financial institution doesn't exist" do
      FinancialInst.stub!(:find_for_user).and_return(nil)
      lambda {
        run
      }.should raise_error(ActiveRecord::RecordNotFound)
    end

  end

  describe "handling GET /financial-institutions/1 as a non-admin" do
    it_should_behave_like "it has a logged-in user"

    before(:each) do
      @fi = mock_model(FinancialInst)
      FinancialInst.stub!(:find_for_user).and_return(@fi)
    end

    it "should raise an ActiveRecord::RecordNotFound exception" do
      FinancialInst.should_receive(:find_for_user).with("1", current_user).and_return(@fi)
      lambda { get :show, :id => "1" }.should raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "handling GET /financial-institutions/1.xml" do
    it_should_behave_like "it has a logged-in user"

    before(:each) do
      @fi = mock_model(FinancialInst)
      FinancialInst.stub!(:find_for_user).and_return(@fi)
    end

    def run
      get :show, :id => "1", :format => "xml"
    end

    it "should find the financial institution" do
      FinancialInst.should_receive(:find_for_user).with("1", current_user).and_return(@fi)
      run
    end

    it "should render the financial institution as XML" do
      controller.should_receive(:render).with(:xml => @fi)
      run
    end

    it "should raise a 404 if the financial institution doesn't exist" do
      FinancialInst.stub!(:find_for_user).and_return(nil)
      lambda {
        run
      }.should raise_error(ActiveRecord::RecordNotFound)
    end

  end

  describe "handling GET /financial-institutions/1 with job and user" do

    before(:each) do
      @job = mock_model(SsuJob)
      @user = mock_model(User)
    end

    it "should authenticate using the job guid and user id" do
      SsuJob.should_receive(:find_by_job_guid).with('abcd').and_return(@job)
      @job.should_receive(:expired?).and_return(false)
      User.should_receive(:find_by_id).with('1234').and_return(@user)
      controller.should_receive(:show)
      get :show, :id => "1", :job_guid => 'abcd', :user_id => '1234'
    end

    it "should fail to authenticate if the user doesn't exist" do
      SsuJob.should_receive(:find_by_job_guid).with('abcd').and_return(@job)
      @job.should_receive(:expired?).and_return(false)
      User.should_receive(:find_by_id).with('1234').and_return(nil)
      get :show, :id => "1", :job_guid => 'abcd', :user_id => '1234'
      response.headers['Status'].should == '401 Unauthorized'
    end

    it "should fail to authenticate if no user id is provided" do
      SsuJob.should_receive(:find_by_job_guid).with('abcd').and_return(@job)
      @job.should_receive(:expired?).and_return(false)
      User.should_receive(:find_by_id).and_return(nil)
      get :show, :id => "1", :job_guid => 'abcd'
      response.headers['Status'].should == '401 Unauthorized'
    end

    it "should fail to authenticate if the job doesn't exist" do
      SsuJob.should_receive(:find_by_job_guid).with('abcd').and_return(nil)
      get :show, :id => "1", :job_guid => 'abcd'
    end

    it "should fail to authenticate if the job is expired" do
      SsuJob.should_receive(:find_by_job_guid).with('abcd').and_return(@job)
      @job.should_receive(:expired?).and_return(true)
      get :show, :id => "1", :job_guid => 'abcd'
    end
  end

  describe "handling PUT /financial-institutions/1" do
    it_should_behave_like "it has an admin user"

    before(:each) do
      @fi = mock_model(FinancialInst, :update_attributes => true, :to_param => 'us-000001')
      FinancialInst.stub!(:find_for_user).and_return(@fi)
    end

    def run
      put :update, :id => "1", :financial_inst => { :name => "Fleedle" }
    end

    it "should find the financial institution" do
      FinancialInst.should_receive(:find_for_user).with("1", anything).and_return(@fi)
      run
    end

    it "should update the financial institution's attributes" do
      @fi.should_receive(:update_attributes).with("name" => "Fleedle").and_return(true)
      run
    end

    it "should redirect to the show page if the financial institution was successfully saved" do
      run
      response.should redirect_to("/financial-institutions/us-000001")
    end

    it "should render financial_insts/edit if the financial institution was not successfully saved" do
      @fi.should_receive(:update_attributes).and_return(false)
      run
      response.should render_template("financial_insts/edit")
    end

    it "should raise a 404 if the financial institution doesn't exist" do
      FinancialInst.stub!(:find_for_user).and_return(nil)
      lambda {
        run
      }.should raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "handling DELETE /financial-institutions/1" do
    it_should_behave_like "it has an admin user"

    before(:each) do
      @fi = mock_model(FinancialInst, :destroy => true)
      FinancialInst.stub!(:find_for_user).and_return(@fi)
    end

    def run
      delete :destroy, :id => "1"
    end

    it "should find the financial institution and assign it to the view" do
      FinancialInst.should_receive(:find_for_user).with("1", anything).and_return(@fi)
      run
      assigns[:financial_inst].should == @fi
    end

    it "should try to destroy the financial institution" do
      @fi.should_receive(:destroy)
      run
    end

    it "should redirect to the unapproved index if the financial institution was successfully deleted" do
      @fi.should_receive(:destroy).and_return(true)
      run
      response.should redirect_to("/financial-institutions/unapproved")
    end

    it "should render financial_insts/destroy if the financial institution was not successfully deleted" do
      @fi.should_receive(:destroy).and_return(false)
      run
      response.should render_template("financial_insts/destroy")
    end

    it "should raise a 404 if the financial institution doesn't exist" do
      FinancialInst.stub!(:find_for_user).and_return(nil)
      lambda {
        run
      }.should raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "handling GET /financial-institutions/1/edit" do
    it_should_behave_like "it has an admin user"

    before(:each) do
      @fi = mock_model(FinancialInst)
      FinancialInst.stub!(:find_for_user).and_return(@fi)
    end

    def run
      get :edit, :id => "1"
    end

    it "should find the financial institution and assign it to the view" do
      FinancialInst.should_receive(:find_for_user).with("1", anything).and_return(@fi)
      run
      assigns[:financial_inst].should == @fi
    end

    it "should render financial_insts/edit" do
      run
      response.should render_template("financial_insts/edit")
    end

    it "should require an admin user" do
      controller.should_receive(:check_for_admin).and_return(true)
      run
    end

    it "should raise a 404 if the financial institution doesn't exist" do
      FinancialInst.stub!(:find_for_user).and_return(nil)
      lambda {
        run
      }.should raise_error(ActiveRecord::RecordNotFound)
    end
  end
end