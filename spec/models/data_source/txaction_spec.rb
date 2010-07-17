require 'spec_helper'

describe DataSource::Txaction do

  before(:each) do
    @merchant = mock_model(Merchant, :id => 500)
    @tag  = mock_model(Tag, :id => 6000)
    @tag2 = mock_model(Tag, :id => 7000)
    @account1 = mock_model(Account, :id => 20)
    @account2 = mock_model(Account, :id => 30)
    @user = mock_model(User, :id => 50, :account_key => "blahblahblah", :accounts => [@account1, @account2])
    @txaction = mock_model(Txaction)
    Txaction.stub!(:find).and_return([@txaction])
    Txaction.stub!(:generate_balance!)

    @ds = DataSource::Txaction.new(@user)
  end

  it "should be Enumerable" do
    DataSource::Txaction.included_modules.should include(Enumerable)
  end

  describe "initializing" do
    it "should require a user" do
      lambda { DataSource::Txaction.new }.should raise_error(ArgumentError)
    end

    it "should not be loaded" do
      DataSource::Txaction.new(@user).should_not be_loaded
    end
  end

  describe "initializing with a block" do
    it "should pass itself to the initialization block" do
      block_ds = nil
      ds = DataSource::Txaction.new(@user) do |init_ds|
        block_ds = init_ds
      end
      block_ds.should eql(ds)
    end

    it "should be loaded after the block is called" do
      ds = DataSource::Txaction.new(@user) do |block_ds|
        block_ds.should_not be_loaded
      end
      ds.should be_loaded
    end
  end

  describe "with an unloaded transaction set" do
    before(:each) do
      @ds = DataSource::Txaction.new(@user)
    end

    it "should have a default status constraint of ACTIVE and PENDING" do
      @ds.statuses.should == [Constants::Status::ACTIVE, Constants::Status::PENDING]
    end

    it "should allow account constraints to be set to a single account" do
      @ds.account = @account1
      @ds.accounts.should == [@account1]
    end

    it "should allow account constraints to be set to a set of accounts" do
      @ds.accounts = [@account1, @account2]
      @ds.accounts.should == [@account1, @account2]
    end

    it "should allow a starting date constraint to be set" do
      @ds.start_date = Time.mktime(2006, 6)
      @ds.start_date.should == Time.mktime(2006, 6)
    end

    it "should allow an ending date constraint to be set" do
      @ds.end_date = Time.mktime(2006, 6)
      @ds.end_date.should == Time.mktime(2006, 6)
    end

    it "should allow merchant constraints to be set to a single merchant" do
      @ds.merchant = @merchant
      @ds.merchants.should == [@merchant]
    end

    it "should allow merchant constraints to be set to a set of merchants" do
      @ds.merchants = [@merchant]
      @ds.merchants.should == [@merchant]
    end

    it "should allow tag constraints to be set to a single tag" do
      @ds.tag = @tag
      @ds.tags.should == [@tag]
    end

    it "should allow tag constraints to be set to a set of tags" do
      @ds.tags = [@tag]
      @ds.tags.should == [@tag]
    end

    it "should allow tag constraints to be set to a single string" do
      Tag.should_receive(:find_by_name).with("foo").and_return(@tag)
      @ds.tag = "foo"
      @ds.tags.should == [@tag]
    end

    it "should allow tag constraints to be set to an array of strings" do
      Tag.should_receive(:find_by_name).with("foo").and_return(@tag)
      Tag.should_receive(:find_by_name).with("bar").and_return(@tag2)
      @ds.tags = ["foo", "bar"]
      @ds.tags.should == [@tag, @tag2]
    end

    it "should not allow tag constraints to be set to a string that is not a tag name" do
      Tag.should_receive(:find_by_name).with("foo").and_return(nil)
      lambda { @ds.tags = "foo" }.should raise_error(ActiveRecord::RecordNotFound)
    end

    it "should allow tag filter constraints to be set to a single tag" do
      @ds.filtered_tag = @tag
      @ds.filtered_tags.should == [@tag]
    end

    it "should allow tag filter constraints to be set to an array of tags" do
      @ds.filtered_tags = [@tag, @tag]
      @ds.filtered_tags.should == [@tag, @tag]
    end

    it "should allow filtered tag constraints to be set to a single string" do
      Tag.should_receive(:find_by_name).with("foo").and_return(@tag)
      @ds.filtered_tags = "foo"
      @ds.filtered_tags.should == [@tag]
    end

    it "should allow filtered tag constraints to be set to an array of strings" do
      Tag.should_receive(:find_by_name).with("foo").and_return(@tag)
      Tag.should_receive(:find_by_name).with("bar").and_return(@tag2)
      @ds.filtered_tags = ["foo", "bar"]
      @ds.filtered_tags.should == [@tag, @tag2]
    end

    it "should not allow tag constraints to be set to a string that is not a tag name" do
      Tag.should_receive(:find_by_name).with("foo").and_return(nil)
      lambda { @ds.filtered_tags = "foo" }.should raise_error(ActiveRecord::RecordNotFound)
    end

    it "should allow required tag constraints to be set to a single tag" do
      @ds.required_tag = @tag
      @ds.required_tags.should == [@tag]
    end

    it "should allow required tag constraints to be set to an array of tags" do
      @ds.required_tag = [@tag, @tag]
      @ds.required_tags.should == [@tag, @tag]
    end

    it "should allow required tag constraints to be set to a single string" do
      Tag.should_receive(:find_by_name).with("foo").and_return(@tag)
      @ds.required_tags = "foo"
      @ds.required_tags.should == [@tag]
    end

    it "should allow required tag constraints to be set to an array of strings" do
      Tag.should_receive(:find_by_name).with("foo").and_return(@tag)
      Tag.should_receive(:find_by_name).with("bar").and_return(@tag2)
      @ds.required_tags = ["foo", "bar"]
      @ds.required_tags.should == [@tag, @tag2]
    end

    it "should not allow tag constraints to be set to a string that is not a tag name" do
      Tag.should_receive(:find_by_name).with("foo").and_return(nil)
      lambda { @ds.required_tags = "foo" }.should raise_error(ActiveRecord::RecordNotFound)
    end

    it "should allow status constraints to be set to a single status" do
      @ds.status = 1
      @ds.statuses.should == [1]
    end

    it "should allow status constraints to be set to a set of statuses" do
      @ds.statuses = [1]
      @ds.statuses.should == [1]
    end

    it "should allow balances to be included" do
      @ds.include_balances = true
      @ds.include_balances.should == true
    end

    it "should default to not rationalizing transactions" do
      @ds.rationalize.should == false
    end

    it "should allow transactions to be rationalized" do
      @ds.rationalize = true
      @ds.rationalize.should == true
    end

    it "should allow transfers to be filtered out" do
      @ds.filter_transfers = true
      @ds.filter_transfers.should == true
    end

    it "should allow amount to be set to positive" do
      @ds.amount = "positive"
      @ds.amount.should == "positive"
      @ds.amount = :positive
      @ds.amount.should == "positive"
      @ds.amount = :earnings
      @ds.amount.should == "positive"
    end

    it "should allow amount to be set to negative" do
      @ds.amount = "negative"
      @ds.amount.should == "negative"
      @ds.amount = :negative
      @ds.amount.should == "negative"
      @ds.amount = :spending
      @ds.amount.should == "negative"
    end

    it "should allow amount to be set to nil" do
      @ds.amount = nil
      @ds.amount.should == nil
    end

    it "should allow untagged to be set" do
      @ds.untagged = true
      @ds.untagged.should == true
    end

    it "should not set untagged if assigned an empty string" do
      @ds.untagged = ""
      @ds.untagged.should == false
    end

    it "should allow unedited to be set" do
      @ds.unedited = true
      @ds.unedited.should == true
    end

    it "should not set unedited if assigned an empty string" do
      @ds.unedited = ""
      @ds.unedited.should == false
    end

  end

  describe "with a loaded transaction set" do
    before(:each) do
      @ds = DataSource::Txaction.new(@user)
      @ds.load!
    end

    it "should be loaded" do
      @ds.should be_loaded
    end

    it "should not load again" do
      Txaction.should_not_receive(:find)
      @ds.load!.should == false
    end

    it "should not allow account constraints to be set" do
      lambda { @ds.account = @account1 }.should raise_error(DataSource::Txaction::ReadOnlyError)
      lambda { @ds.accounts = [@account1] }.should raise_error(DataSource::Txaction::ReadOnlyError)
    end

    it "should not allow a starting date constraint to be set" do
      lambda { @ds.start_date = Time.now }.should raise_error(DataSource::Txaction::ReadOnlyError)
    end

    it "should not allow an ending date constraint to be set" do
      lambda { @ds.end_date = Time.now }.should raise_error(DataSource::Txaction::ReadOnlyError)
    end

    it "should not allow merchant constraints to be set" do
      lambda { @ds.merchant = @merchant }.should raise_error(DataSource::Txaction::ReadOnlyError)
      lambda { @ds.merchants = [@merchant] }.should raise_error(DataSource::Txaction::ReadOnlyError)
    end

    it "should not allow tag constraints to be set" do
      lambda { @ds.tag = @tag }.should raise_error(DataSource::Txaction::ReadOnlyError)
      lambda { @ds.tags = [@tag] }.should raise_error(DataSource::Txaction::ReadOnlyError)
    end

    it "should not allow filter tag constraints to be set" do
      lambda { @ds.filtered_tag = @tag }.should raise_error(DataSource::Txaction::ReadOnlyError)
      lambda { @ds.filtered_tags = [@tag] }.should raise_error(DataSource::Txaction::ReadOnlyError)
    end

    it "should not allow required tag constraints to be set" do
      lambda { @ds.required_tag = @tag }.should raise_error(DataSource::Txaction::ReadOnlyError)
      lambda { @ds.required_tags = [@tag] }.should raise_error(DataSource::Txaction::ReadOnlyError)
    end

    it "should not allow status constraints to be set" do
      lambda { @ds.status = 1 }.should raise_error(DataSource::Txaction::ReadOnlyError)
      lambda { @ds.statuses = [1] }.should raise_error(DataSource::Txaction::ReadOnlyError)
    end

    it "should not allow balances to be included" do
      lambda { @ds.include_balances = true }.should raise_error(DataSource::Txaction::ReadOnlyError)
    end

    it "should not allow transactions to be rationalized" do
      lambda { @ds.rationalize = true }.should raise_error(DataSource::Txaction::ReadOnlyError)
    end

    it "should not allow transfers to be filtered out" do
      lambda { @ds.filter_transfers = true }.should raise_error(DataSource::Txaction::ReadOnlyError)
    end

    it "should not allow amount to be set" do
      lambda { @ds.amount = "positive" }.should raise_error(DataSource::Txaction::ReadOnlyError)
    end
  end

  describe "with an empty transaction set" do
    before(:each) do
      Txaction.stub!(:find).and_return([])
      @ds = DataSource::Txaction.new(@user)
      @ds.load!
    end

    it "should be empty" do
      @ds.should be_empty
    end

    it "should have a size of 0" do
      @ds.size.should == 0
    end

    it "should have a length of 0" do
      @ds.length.should == 0
    end
  end

  describe "with a non-empty transaction set" do
    before(:each) do
      Txaction.stub!(:find).and_return([@txaction])
      @ds = DataSource::Txaction.new(@user)
      @ds.load!
    end

    it "should not be empty" do
      @ds.should_not be_empty
    end

    it "should have a size of 1" do
      @ds.size.should == 1
    end

    it "should have a length of 1" do
      @ds.length.should == 1
    end

    it "should iterate over the set of transactions" do
      items = []
      @ds.each do |i|
        items << i
      end
      items.should == [@txaction]
    end

    it "should sort the set of transactions in place" do
      t1, t2 = mock_model(Txaction, :amount => -25, :<=> => -1), mock_model(Txaction, :amount => -50, :<=> => 1)
      Txaction.stub!(:find).and_return([t1, t2])
      ds = DataSource::Txaction.new(@user)
      ds.load!
      ds.sort!.should == [t1, t2]
      ds.sort! { |a, b| a.amount <=> b.amount }.should == [t2, t1]
    end
  end

  describe "loading transactions without constraints" do
    it "should select all transactions in a user's accounts" do
      Txaction.should_receive(:find).with(:all, hash_including(:conditions =>
        ["(txactions.account_id IN (?)) AND (txactions.status IN (?))", [20, 30], [0, 6]])
      ).and_return([@txaction])

      @ds.load!
      @ds.txactions.should == [@txaction]
    end
  end

  describe "loading transactions with balances" do
    before(:each) do
      @ds.include_balances = true
    end

    it "should generate balances after loading them" do
      Txaction.should_receive(:find).with(any_args).and_return([@txaction])
      Txaction.should_receive(:generate_balances!).with([@txaction])
      @ds.load!
    end
  end

  describe "loading transactions with rationalization" do
    before(:each) do
      @ds.rationalize = true
      @ds.should_receive(:rationalize!)
    end

    it "should rationalize tags of transactions" do
      Txaction.should_receive(:find).and_return([@txaction])
      @ds.load!
    end

    it "should include as much data needed for rationalization as possible" do
      Txaction.should_receive(:find).with(:all, hash_including(:include =>
        [:merchant, :account, {:taggings => :tag}, :txaction_type])
      ).and_return([@txaction])

      @ds.load!
      @ds.txactions.should == [@txaction]
    end
  end

  describe "loading transactions with an account constraint" do
    before(:each) do
      @ds.account = @account1
    end

    it "should select all transactions in the specified account(s)" do
      Txaction.should_receive(:find).with(:all, hash_including(:conditions =>
        ["(txactions.account_id IN (?)) AND (txactions.status IN (?))", [20], [0, 6]]
      )).and_return([@txaction])

      @ds.load!
      @ds.txactions.should == [@txaction]
    end
  end

  describe "loading transactions with a merchant constraint" do
    before(:each) do
      @ds.merchant = @merchant
    end

    it "should select all transactions for the specified merchant" do
      Txaction.should_receive(:find).with(:all, hash_including(:conditions =>
        ["(txactions.account_id IN (?)) AND (txactions.merchant_id IN (?)) AND (txactions.status IN (?))", [20, 30], [500], [0, 6]]
      )).and_return([@txaction])

      @ds.load!
      @ds.txactions.should == [@txaction]
    end
  end

  describe "loading transactions with a tag constraint" do
    before(:each) do
      @ds.tag = @tag
    end

    it "should select all transactions for the specified tag" do
      Txaction.should_receive(:find).with(:all, hash_including(
        :joins => "JOIN txaction_taggings AS included_taggings ON included_taggings.txaction_id = txactions.id",
        :conditions => ["(txactions.account_id IN (?)) AND (txactions.status IN (?)) AND (included_taggings.tag_id IN (?))", [20, 30], [0, 6], [6000]]
      )).and_return([@txaction])

      @ds.load!
      @ds.txactions.should == [@txaction]
    end
  end

  describe "loading transactions with a starting date constraint" do
    before(:each) do
      @ds.start_date = Time.mktime(2006, 1, 13)
    end

    it "should select all transactions posted after the starting date" do
      Txaction.should_receive(:find).with(:all, hash_including(:conditions =>
        ["(txactions.account_id IN (?)) AND (txactions.status IN (?)) AND (txactions.date_posted >= ?)", [20, 30], [0, 6], Time.mktime(2006, 1, 13)]
      )).and_return([@txaction])

      @ds.load!
      @ds.txactions.should == [@txaction]
    end
  end

  describe "loading transactions with an ending date constraint" do
    before(:each) do
      @ds.end_date = Time.mktime(2006, 1, 13)
    end

    it "should select all transactions posted before the ending date" do
      Txaction.should_receive(:find).with(:all, hash_including(:conditions =>
        ["(txactions.account_id IN (?)) AND (txactions.status IN (?)) AND (txactions.date_posted <= ?)", [20, 30], [0, 6], Time.mktime(2006, 1, 13).end_of_day]
      )).and_return([@txaction])

      @ds.load!
      @ds.txactions.should == [@txaction]
    end
  end

  describe "loading transactions with an ending time constraint" do
    before(:each) do
      @ds.end_time = Time.mktime(2006, 1, 13, 03, 45, 00)
    end

    it "should select all transactions posted before the ending time" do
      Txaction.should_receive(:find).with(:all, hash_including(:conditions =>
        ["(txactions.account_id IN (?)) AND (txactions.status IN (?)) AND (txactions.date_posted <= ?)", [20, 30], [0, 6], Time.mktime(2006, 1, 13, 03, 45, 00)]
      )).and_return([@txaction])

      @ds.load!
      @ds.txactions.should == [@txaction]
    end
  end

  describe "loading transactions with starting and ending date constraints" do
    before(:each) do
      @ds.start_date = Time.mktime(2006, 1, 1)
      @ds.end_date = Time.mktime(2006, 1, 13)
    end

    it "should select all transactions posted before the starting date and after the ending date" do
      Txaction.should_receive(:find).with(:all, hash_including(:conditions =>
        ["(txactions.account_id IN (?)) AND (txactions.status IN (?)) AND (txactions.date_posted >= ?) AND (txactions.date_posted <= ?)", [20, 30], [0, 6], Time.mktime(2006, 1, 1), Time.mktime(2006, 1, 13).end_of_day]
      )).and_return([@txaction])

      @ds.load!
      @ds.txactions.should == [@txaction]
    end
  end

  describe "loading transactions with a status constraint" do
    before(:each) do
      @ds.status = 1
    end

    it "should select all transactions for the specified status" do
      Txaction.should_receive(:find).with(:all, hash_including(:conditions =>
        ["(txactions.account_id IN (?)) AND (txactions.status IN (?))", [20, 30], [1]]
      )).and_return([@txaction])

      @ds.load!
      @ds.txactions.should == [@txaction]
    end
  end

  describe "loading with a paginator" do
    it "should add the paginator's offset, limit, and conditions to the query" do
      paginator = stub(:paginator, :limit => 30, :offset => 60, :conditions => { :blue => true })

      Txaction.should_receive(:find).with(:all, hash_including(
        :conditions => ["(blue = ?) AND (txactions.account_id IN (?)) AND (txactions.status IN (?))", true, [20], [0, 6]],
        :limit => 30,
        :offset => 60
      )).and_return([@txaction])

      @ds = DataSource::Txaction.new(@user, paginator) do |ds|
        ds.account = @account1
      end

      @ds.txactions.should == [@txaction]
    end
  end

  describe "loading transactions with a filtered tag constraint" do
    before(:each) do
      @ds.filtered_tags = [@tag, @tag2]
    end

    it "should not select transactions tagged with filtered tags but not tagged with splits" do
      Txaction.should_receive(:find).with(:all, hash_including(
        :joins => "LEFT OUTER JOIN txaction_taggings AS filtered_taggings ON ( filtered_taggings.txaction_id = txactions.id AND filtered_taggings.tag_id IN (6000,7000) ) LEFT OUTER JOIN txaction_taggings AS split_taggings ON ( split_taggings.txaction_id = txactions.id AND split_taggings.split_amount IS NOT NULL )",
        :conditions => ["(txactions.account_id IN (?)) AND (txactions.status IN (?)) AND ((filtered_taggings.txaction_id IS NOT NULL AND split_taggings.split_amount IS NOT NULL) OR (filtered_taggings.txaction_id IS NULL))", [20, 30], [0, 6]]
      )).and_return([@txaction])

      @ds.load!
      @ds.txactions.should == [@txaction]
    end
  end

  describe "loading transactions with a required tag constraint" do
    before(:each) do
      @ds.required_tags = [@tag, @tag2]
    end

    it "should select all transactions tagged with all of the required tags" do
      Txaction.should_receive(:find).with(:all, hash_including(
        :joins => "LEFT OUTER JOIN ( SELECT txaction_id, COUNT(*) AS times_tagged FROM txaction_taggings WHERE tag_id IN (6000,7000) GROUP BY txaction_id ) AS required_taggings ON required_taggings.txaction_id = txactions.id",
        :conditions => ["(txactions.account_id IN (?)) AND (txactions.status IN (?)) AND (required_taggings.times_tagged = ?)", [20, 30], [0, 6], 2]
      )).and_return([@txaction])

      @ds.load!
      @ds.txactions.should == [@txaction]
    end
  end

  describe "loading transactions with transfer filtering turned on" do
    before(:each) do
      @ds.filter_transfers = true
    end

    it "should exclude transactions with a transfer_txaction_id" do
      Txaction.should_receive(:find).with(:all, hash_including(:conditions =>
        ["(txactions.account_id IN (?)) AND (txactions.status IN (?)) AND (txactions.transfer_txaction_id IS NULL)", [20, 30], [0, 6]]
      )).and_return([@txaction])

      @ds.load!
      @ds.txactions.should == [@txaction]
    end
  end

  describe "loading transactions with an unedited constraint" do
    before(:each) do
      @ds.unedited = true
    end

    it "should only include transactions with null merchant_id" do
      Txaction.should_receive(:find).with(:all, hash_including(:conditions =>
        ["(txactions.account_id IN (?)) AND (txactions.status IN (?)) AND (txactions.merchant_id IS NULL)", [20, 30], [0, 6]]
      )).and_return([@txaction])

      @ds.load!
      @ds.txactions.should == [@txaction]
    end
  end

  describe "loading transactions with an untagged constraint" do
    before(:each) do
      @ds.untagged = true
    end

    it "should only include transactions with tagged set to zero and with a NULL transfer_txaction_id" do
      Txaction.should_receive(:find).with(:all, hash_including(:conditions =>
        ["(txactions.account_id IN (?)) AND (txactions.status IN (?)) AND (txactions.tagged = 0) AND (txactions.transfer_txaction_id IS NULL)", [20, 30], [0, 6]]
      )).and_return([@txaction])

      @ds.load!
      @ds.txactions.should == [@txaction]
    end
  end


  describe "loading transactions with amount set" do
    it "should select all transactions with a positive amount" do
      @ds.amount = "positive"
      Txaction.should_receive(:find).with(:all, hash_including(:conditions =>
        ["(txactions.account_id IN (?)) AND (txactions.status IN (?)) AND (txactions.amount > 0)", [20, 30], [0, 6]]
      )).and_return([@txaction])

      @ds.load!
      @ds.txactions.should == [@txaction]
    end

    it "should select all transactions with a negative amount" do
      @ds.amount = "negative"
      Txaction.should_receive(:find).with(:all, hash_including(
        :conditions => ["(txactions.account_id IN (?)) AND (txactions.status IN (?)) AND (txactions.amount < 0)", [20, 30], [0, 6]]
      )).and_return([@txaction])

      @ds.load!
      @ds.txactions.should == [@txaction]
    end
  end

  it "should have extensive tests for the rationalization method"
  it "should have state-based tests to ensure that the tagging objects are in fact all being returned when :include => :taggings"
end
