require 'spec_helper'


describe Merchant do
  describe "mapped to a canonical merchant" do
    before do
      @merchant = Merchant.new(:canonical_merchant_id => 300)
    end

    it "should return the canonical merchant's id as the visible id" do
      @merchant.visible_id.should == 300
    end
  end

  describe "not mapped to a canonical merchant" do
    before do
      @merchant = Merchant.new
      @merchant.stub!(:id).and_return(30)
    end

    it "should return its own id as the visible id" do
      @merchant.visible_id.should == 30
    end
  end

  describe "find_visible_and_canonical" do
    before do
      @foo = Merchant.create(:name => "Foo")
      @bar = Merchant.create(:name => "Bar")
      @baz = Merchant.create(:name => "Baz", :canonical_merchant_id => @bar.id)
      [@foo, @bar, @baz].each {|m| m.stub!(:summary).and_return(true) }

      Merchant.stub!(:find_visible).and_return([ @foo, @bar, @baz ])
    end

    it "should preserve order" do
      Merchant.find_visible_and_canonical([@bar.id,@baz.id,@foo.id], nil).should == [@bar, @baz, @foo]
    end

    it "should not return the canonical merchant more than once" do
      Merchant.find_visible_and_canonical([@foo.id,@bar.id,@baz.id], nil).should == [@foo, @bar, @baz]
    end
  end
end

describe "Merchants: a new merchant" do
  before do
    @merchant = Merchant.new
  end

  it "should strip whitespace from the name before validating" do
    @merchant.name = "  Whoah Now It's The Trailing Whitespace Patrol    "
    @merchant.valid?
    @merchant.name.should == "Whoah Now It's The Trailing Whitespace Patrol"
  end


  it "should be invalid without a name" do
    @merchant.should_not be_valid
    @merchant.should have(1).error_on(:name)
  end

  it "should be invalid without a unique name" do
    whole_foods = Merchant.make(:name => 'Whole Foods')

    @merchant.name = whole_foods.name
    @merchant.should_not be_valid
    @merchant.should have(1).error_on(:name)
  end
end

describe Merchant, 'with no users' do
  before do
    @test_merchant = Merchant.new(:name => "merchant with no users")
    @test_merchant.save!
  end

  after do
    @test_merchant.destroy
  end

  it "should not have a user" do
    @test_merchant.uncached_users_count.should be(0)
  end

  it "should not have any suggested tags" do
    @test_merchant.suggested_tags.length.should be(0)
  end
end

describe Merchant, 'request for the most popular merchant' do
  it "should return nil if the filtered name of the merchant is UNKNOWN" do
    Merchant.get_most_popular_merchant("UNKOWN PAYEE", -1).should be_nil
  end

  it "should return nil if the filtered name of the merchant is ACH PAYMENT" do
    Merchant.get_most_popular_merchant("ACH PAYMENT", -1).should be_nil
  end
end

describe Merchant, 'request for the most popular merchant by user starting with a name' do
  before do
    @user = User.make
  end

  it "should return Berkeley Bowl" do
    Merchant.get_most_popular_by_user_starting_with(@user, "Berk").should_not be_nil
  end

  it "should return an empty array for a non-existent Merchant name" do
    Merchant.get_most_popular_by_user_starting_with(@user, "ZZZZZ").should be_empty
  end
end

describe Merchant, 'request for the most popular merchant starting with a name' do
  it "should return Berkeley Bowl" do
    Merchant.get_most_popular_starting_with("Berk").should_not be_nil
  end

  it "should return an empty array for a non-existent Merchant name" do
    Merchant.get_most_popular_starting_with("ZZZZZZ").should be_empty
  end
end

describe Merchant, "that should be found by name" do
  before do
    @berkeley_bowl = Merchant.make
  end

  it "should find a merchant by name" do
    Merchant.find_by_name(@berkeley_bowl.name).should == @berkeley_bowl
  end

  it "should ignore leading and trailing whitespace when finding a merchant" do
    Merchant.find_by_name("  #{@berkeley_bowl.name}  ").should == @berkeley_bowl
  end

  it "should not find an unedited merchant by name" do
    Merchant.find_edited_by_name("BANK PUKE").should be_nil
  end
end

describe Merchant, "renaming for user" do
  it_should_behave_like "it has a logged-in user"

  before do
    Merchant.delete_all

    @account  = Account.make(:user => current_user)
    @merchant = Merchant.make
    @txaction = Txaction.make(:account => @account, :merchant => @merchant)
  end

  it "should create a merchant with the new name if needed" do
    Merchant.find_by_name("New Merchant").should be_nil
    Merchant.rename_for_user(current_user, @merchant, "New Merchant")
    Merchant.find_by_name("New Merchant").should_not be_nil
  end

  it "should change every transaction with the old merchant to the new merchant" do
    @txaction.merchant.should == @merchant
    @new_merchant = Merchant.rename_for_user(current_user, @merchant, "New Merchant")
    @txaction.reload.merchant.should == @new_merchant
  end
end