require 'spec_helper'


module TagSpecHelper
  def create_tagging(name, taggable = @txaction)
    if taggable.is_a?(Txaction)
      TxactionTagging.create(:txaction => taggable, :name => name, :tag_id => @tag.id)
    else
      Tagging.create(:taggable => taggable, :name => name, :tag_id => @tag.id)
    end
  end
end

describe Tag do
  it_should_behave_like "it has a logged-in user"

  describe "find_all_by_names class method" do
    before do
      Tag.delete_all
      @food = Tag.create(:normalized_name => "food")
      @wine = Tag.create(:normalized_name => "wine")
    end

    it "finds by normalized name" do
      Tag.find_all_by_names("food").should == [@food]
      Tag.find_all_by_names(%w[food]).should == [@food]
      Tag.find_all_by_names(%w[food wine]).should == [@food, @wine]
    end
  end

  describe "find_or_create_by_name class method" do
    before do
      Tag.delete_all
      @food = Tag.create(:normalized_name => "restaurant")
    end

    it "finds by normalized name" do
      tag = Tag.find_or_create_by_name("restaurants")
      tag.should == @food
    end

    it "strips leading and trailing whitespace from tag names" do
      tag = Tag.find_or_create_by_name(" banana ")
      tag.normalized_name.should == "banana"
      tag.user_name.should == "banana"
    end

    context "when passed an empty string" do
      it "returns nil" do
        Tag.find_or_create_by_name("").should be_nil
      end

      it "does not raise an error" do
        lambda { Tag.find_or_create_by_name("") }.should_not raise_error
      end
    end

    context "when passed nil" do
      it "does not raise an error" do
        lambda { Tag.find_or_create_by_name(nil) }.should_not raise_error
      end
    end
  end

  describe "creation" do
    it "does not allow tags with a blank name" do
      @blank = Tag.create(:normalized_name => "")
      @blank.should be_new_record
      @blank.should have(1).error_on(:normalized_name)
    end
  end

  describe "renaming" do
    before do
      @account = Account.make(:user => current_user)
      @merchant = Merchant.make
      @txaction = Txaction.make(:account => @account, :merchant => @merchant)
      @tag = Tag.find_or_create_by_name("beer")
      @txaction.tag_with("beer")
      @tagging = @txaction.taggings.first
      @new = Tag.find_or_create_by_name("alcohol")
    end

    it "changes from one tag to another tag" do
      Tag.rename(current_user, @tag, @new)
      @tagging.reload.tag.should == @new
    end

    it "accepts tags as strings" do
      Tag.rename(current_user, "beer", "alcohol")
      @tagging.reload.tag.should == @new
    end

    it "normalizes strings into tags" do
      Tag.rename(current_user, "BEER", "ALCOHOL")
      @tagging.reload.tag.should == @new
    end

    it "changes tag capitalization" do
      Tag.rename(current_user, "beer", "BEER")
      @tagging.reload.name.should == "BEER"
    end

    it "updates the AMTS table" do
      amts = AccountMerchantTagStat.find_by_account_key_and_merchant_id_and_tag_id(
        current_user.account_key, @merchant.id, @tag.id)

      amts.tag_id.should == @tag.id
      Tag.rename(current_user, @tag.name, @new.name)
      lambda { amts.reload }.should raise_error(ActiveRecord::RecordNotFound)
      AccountMerchantTagStat.find_by_account_key_and_merchant_id_and_tag_id(
        current_user.account_key, @merchant.id, @new.id).should_not be_nil
    end

    describe "with splits" do
      before do
        @txaction.tag_with("sin:50%")
        @tag = Tag.find_by_name("sin")
        @tagging = @txaction.taggings.first
      end

      it "preserves the split in the tagging name" do
        Tag.rename(current_user, "sin", "vice")
        @tagging.reload.name.should == "vice:50%"
      end

      it "preserves the split in the AMTS entry" do
        amts = AccountMerchantTagStat.find_by_account_key_and_merchant_id_and_tag_id(
          current_user.account_key, @merchant.id, @tag.id)

        Tag.rename(current_user, "sin", "vice")
        lambda { amts.reload }.should raise_error(ActiveRecord::RecordNotFound)
        AccountMerchantTagStat.find_by_account_key_and_merchant_id_and_name(
          current_user.account_key, @merchant.id, "vice:50%").should_not be_nil
      end
    end
  end

  describe "deletion for a user" do
    include TagSpecHelper

    before do
      Txaction.delete_all; Account.delete_all; Tag.delete_all

      @account = Account.make(:user => current_user)
      @txaction = Txaction.make(:account => @account)
      @tag = Tag.find_or_create_by_name("beer")
    end

    it "deletes tags by tag object" do
      @tagging = create_tagging("beer")
      Tag.destroy(current_user, @tag)
      Tagging.find_by_id(@tagging.id).should == nil
    end

    it "deletes tags by tag name" do
      @tagging = create_tagging("Beer")
      Tag.destroy(current_user, "Beer")
      Tagging.find_by_id(@tagging.id).should == nil
    end

    it "deletes all tagging variants by tag object" do
      @taggings = %w(beer Beer BeeR beeR BEER).map{|n| create_tagging(n) }
      @tag.txaction_taggings.reload.should contain_same_elements_as(@taggings)
      Tag.destroy(current_user, @tag)
      @tag.txaction_taggings.reload.should == []
    end

    it "deletes all tagging variants by any variants' name" do
      @taggings = %w(beer Beer BeeR beeR BEER).map{|n| create_tagging(n) }
      @tag.txaction_taggings.reload.should == @taggings
      Tag.destroy(current_user, "BeeR")
      @tag.txaction_taggings.reload.should == []
    end

    describe "parsing from a string" do
      it "parses a string of tags into tag objects" do
        tag_list = "groceries chinese"
        tags = Tag.parse_to_tags(tag_list)
        tags.map(&:name).should == ["groceries", "chinese"]
      end

      it "does not include blank tags in the parsed list" do
        Tag.parse_to_tags(",_Allie").map(&:name).should == ["_Allie"]
      end
    end

    it "resets a transaction's tagged status when deleting the last tag" do
      create_tagging(@tag.name)
      @txaction.reload.should be_tagged
      Tag.destroy(current_user, @tag)
      @txaction.reload.should_not be_tagged
    end

  end

  describe "normalize" do
    it "downcases" do
      Tag.normalize("FOOD").should == "food"
    end

    it "strips punctuation" do
      Tag.normalize("hey!").should == "hey"
    end

    it "strips spaces" do
      Tag.normalize("eating out").should == "eatingout"
    end

    it "singularizes" do
      Tag.normalize("cars").should == "car"
    end

    it "returns nil given nil" do
      Tag.normalize(nil).should be_nil
    end

    it "returns nil given an empty string" do
      Tag.normalize("").should be_nil
    end

    it "returns the original given only punctuation" do
      [ "_", "__", "?", "??", "???", "_???", "%", ")"].each do |p|
        Tag.normalize(p).should == p
      end
    end

    it "returns 's' when given 'S' or 's'" do
      %w(s S).each{|l| Tag.normalize(l).should == 's' }
    end

    it "returns punctuation minus spaces" do
      Tag.normalize("? ?").should == "??"
    end
  end

  describe "txaction_count virtual method" do
    before do
      @tag = Tag.new
    end

    it "reads from @attributes" do
      @tag.instance_variable_get("@attributes")['txaction_count'] = '9'
      @tag.txaction_count.should be(9)
    end
  end

  describe "to_param method" do
    before do
      @tag = Tag.new(:user_name => "foo/bar.baz")
    end

    it "escapes slashes" do
      @tag.to_param.should =~ /foo-slash-bar/
    end

    it "escapes dots" do
      @tag.to_param.should =~ /bar-dot-baz/
    end
  end

  describe "decode_name! class method" do
    it "decodes slashes" do
      Tag.decode_name!("foo-slash-bar").should == "foo/bar"
    end

    it "decodes dots" do
      Tag.decode_name!("foo-dot-bar").should == "foo.bar"
    end

    it "accepts empty strings" do
      Tag.decode_name!("").should == ""
    end

    it "accepts nil" do
      Tag.decode_name!(nil).should == nil
    end

    it "changes the string itself, not a copy of the string" do
      original = "foo-slash-bar"
      Tag.decode_name!(original)
      original.should == "foo/bar"
    end
  end
end