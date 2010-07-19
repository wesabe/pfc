require 'spec_helper'

describe TargetsController do
  describe "GET /targets.xml" do
    it_should_behave_like "it has a logged-in user"

    it "should be successful" do
      get :index, :format => "xml"
      response.should be_success
    end
  end

  describe "GET /targets.json" do
    it_should_behave_like "it has a logged-in user"

    it "should be successful" do
      get :index, :format => "json"
      response.should be_success
    end

    describe "with a start_date and end_date" do
      before do
        @start_date = "20090601"
        @end_date = "20090630"
      end

      it "should set the period to include the full start and end dates" do
        get :index, :start_date => @start_date, :end_date => @end_date, :format => "json"
        assigns[:period].should == (Time.parse(@start_date).beginning_of_day..Time.parse(@end_date).end_of_day)
      end
    end
  end


  describe "POST /targets" do
    it_should_behave_like "it has a logged-in user"

    before do
      @account = Account.make(:user => current_user)
      @txaction = Txaction.make(:account => @account)
      @txaction.add_tags('food')
    end

    it "should create a target" do
      post :create, :tag => 'food', :amount => '10'
      response.should be_success
      response.body.should match_json(hash_including("tag" => {"name" => "food"}, "monthly_limit" => hash_including("USD" => 10, "currency" => "USD")))
    end

    it "should strip trailing whitespace from the tag" do
      post :create, :tag => 'food ', :amount => '10'
      response.should be_success
      response.body.should match_json(hash_including("tag" => {"name" => "food"}, "monthly_limit" => hash_including("USD" => 10, "currency" => "USD")))
    end

    it "should return bad_request_status when there is no tag" do
      post :create, :tag => '', :amount => '10'
      response.should be_bad_request
      response.body.should match_json({})
    end


    it "should return bad_request status when there is no amount" do
      post :create, :tag => 'food', :amount => ''
      response.should be_bad_request
      response.body.should match_json({})
    end
  end

  describe "POST /targets/update" do
    it_should_behave_like "it has a logged-in user"

    before do
      @account = Account.make(:user => current_user)
      @txaction = Txaction.make(:account => @account)
      @txaction.add_tags('food')
      @target = Target.create(:tag => Tag.find_by_name('food'), :tag_name => 'food', :amount_per_month => 10, :user => current_user)
    end

    context "given a blank amount" do
      it "does not alter the amount" do
        lambda { post :update, :amount => '', :tag => 'food' }.
          should_not change { @target.reload.amount_per_month }
      end
    end
  end

  describe "POST /targets/edit" do # iPhone app version 1.0
    it_should_behave_like "it has a logged-in user"

    before do
      @account = Account.make(:user => current_user)
      @txaction = Txaction.make(:account => @account)
      @txaction.add_tags('food')
    end

    def do_post
      post :edit, :target => {:mode => '0', :amount_per_month => '200'}, :tag => 'food'
    end

    it "is successful" do
      do_post
      response.should be_success
    end

    it "renders the target as JSON" do
      do_post
      response.body.should match_json(
        "tag" => {
          "name" => "food"
        },
        "monthly_limit" => {"USD" => 200.0, "currency" => "USD"},
        "amount_spent" => {"USD" => 0.0, "currency" => "USD"}
      )
    end
  end

  describe "PUT /targets/:tag" do
    it_should_behave_like "it has a logged-in user"

    before do
      @account = Account.make(:user => current_user)
      @txaction = Txaction.make(:account => @account)
      @txaction.add_tags('food')
      @target = Target.create(:tag => Tag.find_by_name('food'), :tag_name => 'food', :amount_per_month => 10, :user => current_user)
    end

    it "should update the target" do
      lambda {
        put :update, :amount => 11, :tag => 'food'
      }.should change { @target.reload.amount_per_month }.from(10).to(11)
    end
  end

  describe "DELETE /targets/:tag" do
    it_should_behave_like "it has a logged-in user"

    before do
      @account = Account.make(:user => current_user)
      @txaction = Txaction.make(:account => @account)
      @txaction.add_tags('food')
      @target = Target.create(:tag => Tag.find_by_name('food'), :tag_name => 'food', :amount_per_month => 10, :user => current_user)
    end

    it "should delete the target" do
      delete :destroy, :tag => 'food'
      Target.for_tag('food', current_user).should be_nil
    end
  end

end

