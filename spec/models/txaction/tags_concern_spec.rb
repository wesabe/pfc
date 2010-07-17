require 'spec_helper'

describe Txaction do
  it_should_behave_like "it has a logged-in user"

  context "tagging a transaction" do
    before do
      Merchant.delete_all
      @txaction = Txaction.make(:merchant => Merchant.make)
    end

    it "should add tags to a transaction" do
      @txaction.tags.should be_empty
      @txaction.tag_with("foo bar")
      @txaction.tags.map(&:name).should contain_same_elements_as(["bar","foo"])
    end

    it "should not duplicate tags" do
      @txaction.tag_with("foo bar")
      @txaction.tags.map(&:name).should contain_same_elements_as(["bar","foo"])
      @txaction.tag_with("bar baz")
      @txaction.tags.map(&:name).should contain_same_elements_as(["bar","baz"])
    end

    it "should add tags without creating duplicates" do
      @txaction.tag_with("foo bar")
      @txaction.tags.map(&:name).should contain_same_elements_as(["bar","foo"])
      @txaction.add_tags("bar baz")
      @txaction.tags.map(&:name).should contain_same_elements_as(["bar","baz", "foo"])
    end

    it "should remove tags" do
      @txaction.tag_with("foo bar")
      @txaction.tags.map(&:name).should contain_same_elements_as(["bar","foo"])
      @txaction.remove_tags("bar baz")
      @txaction.tags.map(&:name).should contain_same_elements_as(["foo"])
    end

    it "should set the tagged flag on txaction" do
      @txaction.tagged.should be_false
      @txaction.tag_with("foo bar")
      @txaction.tagged.should be_true
    end

    it "should set the tagged flag on txaction when adding a tag" do
      @txaction.tagged.should be_false
      @txaction.add_tag("foo")
      @txaction.tagged.should be_true
    end

    it "should clear the tagged flag on txaction if all tags are deleted" do
      @txaction.tagged.should be_false
      @txaction.tag_with("foo bar")
      @txaction.tagged.should be_true
      @txaction.remove_tag("foo")
      @txaction.tagged.should be_true
      @txaction.remove_tag("bar")
      @txaction.tagged.should be_false
    end

    context "with splits" do
      before do
        @txaction.update_attribute(:amount, -99)
      end

      it "should handle simple splits" do
        @txaction.tag_with("foo:10")
        @txaction.taggings.first.split_amount.should == -10
      end

      it "should handle percentage splits" do
        @txaction.tag_with("foo:10%")
        @txaction.taggings.first.split_amount.should be_close(-9.9, 0.01)
      end

      it "should handle simple fractions" do
        @txaction.tag_with("foo:1/3")
        @txaction.taggings.first.split_amount.should be_close(-33, 0.01)
      end

      it "should handle simple math" do
        @txaction.tag_with("foo:(2*3)+1")
        @txaction.taggings.first.split_amount.should be_close(-7, 0.01)
      end

      it "should ignore tags with a 0 split amount" do
        @txaction.tag_with("foo bar:0")
        @txaction.tags.map(&:name).should contain_same_elements_as(["foo"])
        @txaction.tag_with("foo bar:0.0")
        @txaction.tags.map(&:name).should contain_same_elements_as(["foo"])
        @txaction.tag_with("foo bar:0%")
        @txaction.tags.map(&:name).should contain_same_elements_as(["foo"])
        @txaction.tag_with("foo bar:(2*3)-6")
        @txaction.tags.map(&:name).should contain_same_elements_as(["foo"])
        @txaction.tag_with("foo bar:1")
        @txaction.tags.map(&:name).should contain_same_elements_as(["bar:1", "foo"])
        # make sure that we can unset tags using :0 (see #481)
        @txaction.tag_with("foo bar:0")
        @txaction.tags.map(&:name).should contain_same_elements_as(["foo"])
      end

      it "should update duplicate tags if the split has changed" do
        @txaction.tag_with("foo bar")
        @txaction.tag_with("foo:7 bar")
        @txaction.tags.map(&:name).should contain_same_elements_as(["foo:7", "bar"])
        @txaction.tag_with("foo bar")
        @txaction.tags.map(&:name).should contain_same_elements_as(["foo", "bar"])
      end
    end
  end

  describe "tag_this_and_merchant_untagged_with method" do
    before do
      @account = Account.make(:user => current_user)
      @merchant = Merchant.make
      @txaction = Txaction.make(:account => @account, :merchant => @merchant)
    end

    it "should tag the transaction it is called on" do
      @txaction.tag_this_and_merchant_untagged_with("food")
      @txaction.tags.reload.map(&:name).should include("food")
    end

    context "with another transaction at the same merchant that is untagged" do
      before do
        @untagged = Txaction.make(:account => @account, :merchant => @merchant, :tagged => false)
      end

      after do
        @untagged.destroy
      end

      it "tags the other transaction as well" do
        @txaction.tag_this_and_merchant_untagged_with("food")
        @untagged.tags.reload.map(&:name).should include("food")
      end

      it "returns both transactions that were changed" do
        changed = @txaction.tag_this_and_merchant_untagged_with("food")
        changed.should include(@txaction)
        changed.should include(@untagged)
      end

      context "with split tags" do
        it "should not propagate splits" do
          @txaction.tag_this_and_merchant_untagged_with("food tip:5")
          @untagged.tags.reload.map(&:name).should_not include("tip:5")
        end

        it "should tag the txaction with the split" do
          @txaction.tag_this_and_merchant_untagged_with("food tip:5")
          @txaction.tags.reload.map(&:name).should include("tip:5")
        end
      end

      context "but has had autotags disabled" do
        it "should not tag the other transaction as well" do
          MerchantUser.disable_autotags(@current_user, @merchant, @untagged.amount.sign)
          @txaction.tag_this_and_merchant_untagged_with("food")
          @untagged.tags.reload.map(&:name).should_not include("food")
        end
      end

      context "but has a different sign" do
        it "should not tag the other transaction as well" do
          @untagged.update_attribute(:amount, -@txaction.amount)
          @txaction.tag_this_and_merchant_untagged_with("food")
          @untagged.tags.reload.map(&:name).should_not include("food")
        end
      end

      context "but belongs to another user" do
        it "should not tag that transaction, god dammit" do
          @other_account = Account.make
          @untagged.update_attribute(:account, @other_account)

          @txaction.tag_this_and_merchant_untagged_with("food")
          @untagged.tags.reload.map(&:name).should_not include("food")
        end
      end
    end
  end

  describe "add_tags_for_merchant method" do
    before do
      @account = Account.make(:user => current_user)
      @merchant = Merchant.make
      @txaction = Txaction.make(:account => @account, :merchant => @merchant)
    end

    it "should only add tags to the transactions" do
      @txaction.tag_with("foo bar", true)
      Txaction.add_tags_for_merchant(current_user, @merchant, @txaction.amount.sign, "bar baz")
      @txaction.tags.reload.map(&:name).should contain_same_elements_as(["foo", "bar", "baz"])
    end

    it "should not update txactions with a different sign" do
      @txaction.tag_with("foo bar", true)
      Txaction.add_tags_for_merchant(current_user, @merchant, -@txaction.amount.sign, "bar baz")
      @txaction.tags.reload.map(&:name).should contain_same_elements_as(["foo", "bar"])
    end
  end

  describe "remove_tags_for_merchant method" do
    before do
      @account = Account.make(:user => current_user)
      @merchant = Merchant.make
      @txaction = Txaction.make(:account => @account, :merchant => @merchant)
    end

    it "removes the specified tags from the transactions" do
      @txaction.tag_with("foo bar", true)
      Txaction.remove_tags_for_merchant(current_user, @merchant, @txaction.amount.sign, "foo")
      @txaction.tags.reload.map(&:name).should contain_same_elements_as(["bar"])
    end
  end
end