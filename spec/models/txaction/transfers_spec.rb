require 'spec_helper'

describe Txaction do
  it_should_behave_like 'it has a logged-in user'

  before do
    @account1 = Account.make
    @account2 = Account.make(:account_key => @account1.account_key)

    @tx1 = Txaction.make(:account => @account1)
    @tx2 = Txaction.make(:account => @account2)

    @expected_pair = @tx2
  end

  shared_examples_for 'a non-transfer transaction' do
    it "is not a transfer" do
      @tx1.should_not be_a_transfer
    end

    it "is not a paired transfer" do
      @tx1.should_not be_a_paired_transfer
    end

    it "has a nil transfer_buddy" do
      @tx1.transfer_buddy.should be_nil
    end
  end

  shared_examples_for 'a non-paired transaction' do
    it "is a transfer" do
      @tx1.should be_a_transfer
    end

    it "is not a paired transfer" do
      @tx1.should_not be_a_paired_transfer
    end

    it "has itself as a transfer_buddy" do
      @tx1.transfer_buddy.should == @tx1
    end
  end

  shared_examples_for 'a paired transaction' do
    it "is a transfer" do
      @tx1.should be_a_transfer
    end

    it "is a paired transfer" do
      @tx1.should be_a_paired_transfer
    end

    it "has the pair as transfer_buddy" do
      @tx1.transfer_buddy.should == @expected_pair
    end

    it "sets the pair's transfer buddy to itself" do
      @expected_pair.transfer_buddy.should == @tx1
    end
  end

  context "before establishing a transfer" do
    it_should_behave_like 'a non-transfer transaction'
  end

  context "establishing a non-paired transfer" do
    before do
      @tx1.set_transfer_buddy!(@tx1)
    end

    it_should_behave_like 'a non-paired transaction'
  end

  context "establishing a paired transfer" do
    before do
      @tx1.set_transfer_buddy!(@tx2)
    end

    it_should_behave_like 'a paired transaction'
  end

  context "replacing a non-paired transfer with no transfer" do
    before do
      @tx1.set_transfer_buddy!(@tx1)
      @tx1.clear_transfer_buddy!
      @tx1.reload
      @tx2.reload
    end

    it_should_behave_like 'a non-transfer transaction'
  end

  context "replacing a non-paired transfer with a paired transfer" do
    before do
      @tx1.set_transfer_buddy!(@tx1)
      @tx1.set_transfer_buddy!(@tx2)
      @tx1.reload
      @tx2.reload
    end

    it_should_behave_like 'a paired transaction'
  end

  context "replacing a paired transfer with no transfer" do
    before do
      @tx1.set_transfer_buddy!(@tx2)
      @tx1.clear_transfer_buddy!
      @tx1.reload
      @tx2.reload
    end

    it_should_behave_like 'a non-transfer transaction'

    it "clears its pair's transfer buddy" do
      @tx2.transfer_buddy.should be_nil
    end
  end

  context "replacing a paired transfer with a non-paired transfer" do
    before do
      @tx1.set_transfer_buddy!(@tx2)
      @tx1.set_transfer_buddy!(@tx1)
      @tx1.reload
      @tx2.reload
    end

    it_should_behave_like 'a non-paired transaction'

    it "clears its pair's transfer buddy" do
      @tx2.transfer_buddy.should be_nil
    end
  end

  context "replacing a paired transfer with a different paired transfer" do
    before do
      @account3 = Account.make(:account_key => @account2.account_key)
      @tx3 = Txaction.make(:account => @account3)
      @tx1.set_transfer_buddy!(@tx2)
      @tx1.set_transfer_buddy!(@tx3)
      @tx1.reload
      @tx2.reload
      @tx3.reload
      @expected_pair = @tx3
    end

    it_should_behave_like 'a paired transaction'

    it "clears its pair's transfer buddy" do
      @tx2.transfer_buddy.should be_nil
    end
  end

  context "attaching a transfer to an existing paired transfer" do
    before do
      @account3 = Account.make(:account_key => @account2.account_key)
      @tx3 = Txaction.make(:account => @account3)
      @tx1.set_transfer_buddy!(@tx2)
      @tx3.set_transfer_buddy!(@tx2)
      @tx1.reload
      @tx2.reload
      @tx3.reload
    end

    it_should_behave_like 'a non-paired transaction'
  end
end
