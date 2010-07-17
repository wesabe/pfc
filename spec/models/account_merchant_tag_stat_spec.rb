require 'spec_helper'

describe AccountMerchantTagStat do
  it_should_behave_like "it has a logged-in user"

  before do
    @account = Account.make(:user => current_user)
    @merchant = Merchant.find_by_name("Apple") || Merchant.make(:name => "Apple")
    @tag = Tag.find_or_create_by_name("foo")
    @sign = -1
    @amts = AccountMerchantTagStat.find_or_create(
      current_user.account_key, @merchant.id, @sign, @tag.id, "foo")
    @amts.should be_valid
  end

  describe "find_or_create method" do
    before do
      @new_tag = Tag.find_or_create_by_name("new_tag")
      @amts_attrs = [current_user.account_key, @merchant.id, @sign, @new_tag.id, "new_tag"]
    end

    describe "something nested" do
      it "should create a new record if one doesn't exist" do
        lambda {
          @amts = AccountMerchantTagStat.find_or_create(*@amts_attrs)
        }.should change(AccountMerchantTagStat, :count).by(1)
      end

      it "should find a record if it already exists" do
        @amts = AccountMerchantTagStat.find_or_create(*@amts_attrs)
        @second_amts = AccountMerchantTagStat.find_or_create(*@amts_attrs)
        @amts.should == @second_amts
      end
    end
  end

  describe "increment_tags method" do
    it "should update the counts involved" do
      lambda {
        AccountMerchantTagStat.increment_tags(current_user, @merchant, @sign, "foo").should include(@amts)
      }.should change{ @amts.reload.count }.by(1)
    end

    it "should create separate records for different names for the same tag" do
      AccountMerchantTagStat.increment_tags(current_user, @merchant, @sign, "foos").should_not include(@amts)
    end

    it "should create separate records for different signs" do
      AccountMerchantTagStat.increment_tags(current_user, @merchant, -@sign, "foo").should_not include(@amts)
    end

    it "should create separate records for different splits" do
      AccountMerchantTagStat.increment_tags(current_user, @merchant, @sign, "foo:10").should_not include(@amts)
    end

    it "should not count splits of zero dollars (the old anti-sticky hack)" do
      lambda {
        AccountMerchantTagStat.increment_tags(current_user, @merchant, @sign, "foo:0")
      }.should_not change{ AccountMerchantTagStat.count }
    end

    context "when given two tags" do
      before(:each) do
        @bar = Tag.find_or_create_by_name("bar")
        @bar_amts = AccountMerchantTagStat.find_or_create(current_user.account_key, @merchant.id, @sign, @bar.id, "bar:10")
        @foo_count, @bar_count = @amts.count, @bar_amts.count
      end

      it "should update both tags at once" do
        AccountMerchantTagStat.increment_tags(current_user, @merchant, @sign, "foo bar:10")
        @amts.reload.count.should == @foo_count + 1
        @bar_amts.reload.count.should == @bar_count + 1
      end

      it "should accept the tag names as an array" do
        AccountMerchantTagStat.increment_tags(current_user, @merchant, @sign, ["foo", "bar:10"])
        @amts.reload.count.should == @foo_count + 1
        @bar_amts.reload.count.should == @bar_count + 1
      end
    end
  end

  describe "update method" do
    it "should allow tags to be incremented" do
      lambda {
        AccountMerchantTagStat.update_record(current_user, @merchant, @sign, "foo", :change => :increment)
      }.should change{ @amts.reload.count }.by(1)
    end

    it "should allow tags to be decremented" do
      lambda {
        AccountMerchantTagStat.update_record(current_user, @merchant, @sign, "foo", :change => :decrement)
      }.should change{ @amts.reload.count }.by(-1)
    end

    it "should allow tags to be forced on" do
      AccountMerchantTagStat.update_record(current_user, @merchant, @sign, "foo", :force => 1)
      @amts.reload.forced.should == 1
    end

    it "should allow tags to be forced off" do
      AccountMerchantTagStat.update_record(current_user, @merchant, @sign, "foo", :force => -1)
      @amts.reload.forced.should == -1
    end

    it "should allow tags to be forced to automatic" do
      AccountMerchantTagStat.update_record(current_user, @merchant, @sign, "foo", :force => 0)
      @amts.reload.forced.should == 0
    end

    it "should raise an error if options is not a hash" do
      lambda {
        AccountMerchantTagStat.increment_tags(current_user, @merchant, @sign, "foo", -1)
      }.should raise_error(ArgumentError)
    end

    it "should raise an error if no force or change option" do
      lambda {
        AccountMerchantTagStat.increment_tags(current_user, @merchant, @sign, "foo", {:foo => "bar"})
      }.should raise_error(ArgumentError)
    end
  end


  describe "total for merchant" do
    it "should return the number of tagged transactions with this merchant" do
      lambda {
        Txaction.make(:account => @account, :merchant_id => @merchant.id, :tagged => true)
      }.should change{ AccountMerchantTagStat.total_for_merchant(current_user, @merchant, @sign) }
    end
  end

  describe "total for tag" do
    it "should return the sum of the counts for all names with this tag" do
      AccountMerchantTagStat.increment_tags(current_user, @merchant, @sign, "foo foo:10 foo:20")
      @tag = Tag.find_or_create_by_name("foo")
      AccountMerchantTagStat.total_for_tag(current_user, @merchant, @sign, @tag).should == 3
    end
  end

end

describe AccountMerchantTagStat, "autotags for" do
  it_should_behave_like 'it has a logged-in user'

  before do
    @account = Account.make(:user => current_user)
    @merchant = Merchant.make
    @sign = -1
    (1..10).each do |i|
      ts = "food"
      (i % 5).zero? ? ts << " cash" : ts << " yummy"
      AccountMerchantTagStat.increment_tags(current_user, @merchant, @sign, ts)
    end

    AccountMerchantTagStat.stub!(:total_for_merchant).and_return(10)
  end

  after do
    [current_user, @account, @merchant].each{|n| n.destroy if n }
  end

  it "should take a user, merchant, and sign" do
    lambda {
      AccountMerchantTagStat.autotags_for(current_user, @merchant, @sign)
    }.should_not raise_error
  end

  it "should return an array of amts objects" do
    AccountMerchantTagStat.autotags_for(current_user, @merchant, @sign).each do |amts|
      amts.should be_an(AccountMerchantTagStat)
    end
  end

  it "should provide a string form" do
    AccountMerchantTagStat.autotags_string_for(current_user, @merchant, @sign).should be_a(String)
  end

  it "should only return tags used in 80% of transactions" do
    autotags = AccountMerchantTagStat.autotags_string_for(current_user, @merchant, @sign)
    autotags.should == "food yummy"
    autotags.should include("food")
    autotags.should include("yummy")
    autotags.should_not include("cash")
  end

  it "should only return tags that have been used a minimum number of times" do
    silence_warnings do
      AccountMerchantTagStat::AUTOTAG_MINIMUM_TXACTIONS = 11
      autotags = AccountMerchantTagStat.autotags_string_for(current_user, @merchant, @sign)
      autotags.should == ""
      AccountMerchantTagStat::AUTOTAG_MINIMUM_TXACTIONS = 9
      autotags = AccountMerchantTagStat.autotags_string_for(current_user, @merchant, @sign)
      autotags.should == "food"
      AccountMerchantTagStat::AUTOTAG_MINIMUM_TXACTIONS = 3
    end
  end

  it "should count the same tag_id together" do
    6.times { AccountMerchantTagStat.increment_tags(current_user, @merchant, @sign, "cashes") }
    # tag_id "cash" is now used 8 times, and "cashes" is the more common version, so it should be suggested
    AccountMerchantTagStat.autotags_string_for(current_user, @merchant, @sign).should include("cashes")
  end

  it "should not count splits" do
    10.times { AccountMerchantTagStat.increment_tags(current_user, @merchant, @sign, "fee:5") }
    AccountMerchantTagStat.autotags_string_for(current_user, @merchant, @sign).should_not include("fee:5")
  end

  it "should be fine" do
    AccountMerchantTagStat.force_on(current_user, @merchant, @sign, "bizarro")
  end

  it "should only return forced tags if there are any forced tags" do
    AccountMerchantTagStat.force_on(current_user, @merchant, @sign, "bizarro")
    AccountMerchantTagStat.autotags_string_for(current_user, @merchant, @sign).should == "bizarro"
    AccountMerchantTagStat.auto_on(current_user, @merchant, @sign, "bizarro")
  end

  it "should not try to further parse a tags_list that's an array" do
    AccountMerchantTagStat.force_on(current_user, @merchant, @sign, ["mortgage insurance"])
    AccountMerchantTagStat.autotags_string_for(current_user, @merchant, @sign).should == %{"mortgage insurance"}
  end

  it "should allow forced tags to be switched back to automatic" do
    AccountMerchantTagStat.force_on(current_user, @merchant, @sign, "bizarro")
    AccountMerchantTagStat.autotags_string_for(current_user, @merchant, @sign).should == "bizarro"
    AccountMerchantTagStat.auto_on(current_user, @merchant, @sign, "bizarro")
    AccountMerchantTagStat.autotags_string_for(current_user, @merchant, @sign).should_not include("bizarro")
  end

  it "should allow tags with splits to be forced on" do
    AccountMerchantTagStat.force_on(current_user, @merchant, @sign, "fee:5")
    AccountMerchantTagStat.autotags_string_for(current_user, @merchant, @sign).should == "fee:5"
    AccountMerchantTagStat.auto_on(current_user, @merchant, @sign, "fee:5")
  end

  it "should allow tags with splits to be forced back to automatic" do
    AccountMerchantTagStat.force_on(current_user, @merchant, @sign, "fee:5")
    AccountMerchantTagStat.autotags_string_for(current_user, @merchant, @sign).should == "fee:5"
    AccountMerchantTagStat.auto_on(current_user, @merchant, @sign, "fee:5")
    AccountMerchantTagStat.autotags_string_for(current_user, @merchant, @sign).should_not include("fee:5")
  end

  it "should not return any tags that have been forced off" do
    AccountMerchantTagStat.force_off(current_user, @merchant, @sign, "food")
    AccountMerchantTagStat.autotags_for(current_user, @merchant, @sign).should_not include("food")
  end

  it "should not return any tags if autotags have been disabled" do
    MerchantUser.should_receive(:autotags_disabled?).and_return(true)
    AccountMerchantTagStat.autotags_for(current_user, @merchant, @sign).should == []
  end
end

describe AccountMerchantTagStat, "fix! method" do
  it_should_behave_like "it has a logged-in user"

  before do
    AccountMerchantTagStat.delete_all
    @account = Account.make(:user => current_user)
    @merchant = Merchant.make
    @other_merchant = Merchant.make
    @extinct_merchant = Merchant.make
    @txactions = [
      Txaction.make(:account => @account, :merchant => @merchant),
      Txaction.make(:account => @account, :merchant => @merchant)
    ]
    @txactions.each {|txaction| txaction.tag_with("foo bar:50%") }
    @other_txactions = [
      Txaction.make(:account => @account, :merchant => @other_merchant),
      Txaction.make(:account => @account, :merchant => @other_merchant)
    ]
    @other_txactions.each {|txaction| txaction.tag_with("baz") }

    # now mess up the AMTS table
    AccountMerchantTagStat.update_all("count = count - 1", ["account_key = ?", current_user.account_key])
    @extinct_amts = AccountMerchantTagStat.create!(
      :account_key => current_user.account_key,
      :merchant => @extinct_merchant,
      :tag => Tag.find_or_create_by_name("foo"),
      :name => "foo",
      :count => -1,
      :sign => -1)
  end

  it "should fix the counts" do
    lambda {
      AccountMerchantTagStat.fix!(current_user.account_key)
    }.should change {
      AccountMerchantTagStat.sum(:count, :conditions => ["account_key = ?", current_user.account_key])
    }.from(2).to(6)
  end

  it "should delete amts entries that are no longer used" do
    AccountMerchantTagStat.fix!(current_user.account_key)
    lambda { @extinct_amts.reload }.should raise_error(ActiveRecord::RecordNotFound)
  end
end