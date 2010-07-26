require 'spec_helper'

describe RationalTxactionsController do
  it_should_behave_like "it has a logged-in user"

  before do
    @tags = %w(foo bar/baz).map{|t| Tag.find_or_create_by_name(t) }
  end

  after do
    @tags.each(&:destroy)
  end

  before do
    current_user.stub!(:filter_tags).and_return([mock_model(Tag, :name => "qux")])
    current_user.stub!(:accounts).and_return([mock_model(Account, :id => 1)])
    current_user.stub!(:account_key).and_return(123)

    @ds = DataSource::Txaction.new(current_user)
    @ds.stub!(:rationalize!)
    DataSource::Txaction.stub!(:new).and_yield(@ds).and_return(@ds)
  end

  describe "index action" do

    it "should succeed" do
      xhr :get, :index
      response.should be_success
    end

    it "should provide an XML response" do
      xhr :get, :index
      response.headers["type"].should =~ /^application\/xml/
    end

    it "should render the index template" do
      xhr :get, :show, :tags => "foo"
      response.should render_template("index")
    end

    it "should assign txactions" do
      xhr :get, :index
      assigns[:txactions].should == @ds.txactions
    end

    it "should rationalize transactions" do
      xhr :get, :index
      @ds.rationalize.should be_true
    end

    it "should set the start date" do
      date = "20080101"
      xhr :get, :index, :start_date => date
      @ds.start_date.should == Time.parse(date)
    end

    it "should set the end date" do
      date = "20080101"
      xhr :get, :index, :end_date => date
      @ds.end_date.should == Time.parse(date)
    end

    it "should filter the user's filter tags" do
      xhr :get, :index
      @ds.filtered_tags.should == current_user.filter_tags
    end

    describe "with type :spending" do
      it "should set the data source amount to negative" do
        xhr :get, :index, :type => :spending
        @ds.amount.should == "negative"
      end
    end

    describe "with type :earnings" do
      it "should set the data source amount to positive" do
        xhr :get, :index, :type => :earnings
        @ds.amount.should == "positive"
      end
    end
  end
end