require 'spec_helper'

module TxactionSpecHelper
  def create_and_attach_txaction(attributes = {})
    attributes.reverse_merge! :amount => 27.32, :date_posted => Date.today, :status => Constants::Status::ACTIVE, :account => @account
    if attributes[:debit]
      attributes.delete :debit
      attributes[:amount] = -attributes[:amount]
      attributes[:account] = @account2 if attributes[:account] == @account
    end

    tx1 = Txaction.make(attributes)
    tx1.attach_matching_transfer
    tx1.save!
    return tx1
  end
end

describe Txaction do
  it_should_behave_like "it has a logged-in user"

  it "should have a unique, opaque GUID" do
    @txaction = Txaction.new
    @txaction.stub!(:id).and_return(300)
    @txaction.guid.should == "5a36b09bb30ac9eb967c1dd1fec2318eab52038e086b99b772b9ffa3d245d487"
  end

  describe "A transaction" do
    before do
      @account = Account.make(:user => current_user)
      @txaction = Txaction.make(:account => @account)
    end

    describe "#taggings" do
      it "omits taggings that have 0 amount" do
        @txaction.tag_with("food:0 gift")
        @txaction.taggings.should have(1).tagging
        @txaction.taggings.first.name.should == "gift"
        @txaction.taggings.first.usd_split_amount.should be_nil
      end
    end

    it "should find txactions by user and tag" do
      tag = Tag.find_or_create_by_name("food")
      @txaction.tag_with("food")
      Txaction.find_by_user_and_tag(current_user, tag).should include(@txaction)
      # try passing in a condition
      Txaction.find_by_user_and_tag(current_user, tag, :conditions => ['raw_name = ?', @txaction.raw_name]).size.should == 1
    end

    it "should generate balances for a set of transactions" do
      account = Account.new(:id => 1)
      account.stub!(:cash_account?).and_return(false)
      account.stub!(:balance).and_return(100)
      txactions = [
        Txaction.new(:account => account, :date_posted => Time.now - 2.days, :amount => -1, :sequence => 1),
        Txaction.new(:account => account, :date_posted => Time.now - 1.day, :amount => -1, :sequence => 1),
        Txaction.new(:account => account, :date_posted => Time.now - 1.day, :amount => -1, :sequence => 2),
        Txaction.new(:account => account, :date_posted => Time.now, :amount => -1, :sequence => 1),
      ]
      Txaction.generate_balances!(txactions)
      txactions[0].balance.should == 100
      txactions[3].balance.should == 103
    end

    it "should generate balances for a manual account with last balance in the past" do
      account = Account.make(:manual, :user => current_user)
      last_balance = AccountBalance.make(:account => account, :balance => 100,
                      :balance_date => 2.days.ago, :created_at => 2.days.ago)
      txactions = [
        Txaction.make(:account => account, :date_posted => Time.now, :amount => -1),
        Txaction.make(:account => account, :date_posted => 1.day.ago, :amount => -1),
        Txaction.make(:account => account, :date_posted => 3.days.ago, :amount => -1),
        Txaction.make(:account => account, :date_posted => 4.days.ago, :amount => -1),
      ]
      Txaction.generate_balances!(txactions)
      txactions.first.balance.should == 98
      txactions.last.balance.should == 101
    end

    it "should generate balances for a manual account with last balance in the future (relative to most recent txaction)" do
      account = Account.make(:manual, :user => current_user)
      last_balance = AccountBalance.make(:account => account, :balance => 100,
                      :balance_date => Time.now, :created_at => Time.now)
      txactions = [
        Txaction.make(:account => account, :date_posted => 1.day.ago, :amount => -1),
        Txaction.make(:account => account, :date_posted => 2.days.ago, :amount => -1),
      ]
      Txaction.generate_balances!(txactions)
      txactions.first.balance.should == 100
      txactions.last.balance.should == 101
    end

  end

  describe "merchant name editing" do

    before do
      @txaction = Txaction.new
    end

    def assert_edit_independently(names)
      names.to_a.each do |name|
        @txaction.filtered_name = name
        assert @txaction.edit_independently?, name
      end
    end

    def assert_not_edit_independently(names)
      names.to_a.each do |name|
        @txaction.filtered_name = name
        assert !@txaction.edit_independently?, name
      end
    end

    it "should be independent for checks" do
      @txaction.stub!(:is_check?).and_return(true)
      assert @txaction.edit_independently?
    end

    it "should be independent for generic withdrawals" do
      assert_edit_independently %w{WITHDRAWAL ELECTRONICWITHDRAWAL INTERNETWITHDRAWAL}
    end

    it "should be independent for generic deposits" do
      assert_edit_independently %w{DEPOSIT ATMDEPOSIT ELECTRONICDEPOSIT INTERNETDEPOSIT ABCINSTANTTELLERDEPOSITXYZ DEPOSITHOME}
    end

    it "should be independent for ATM and generic merchants" do
      assert_edit_independently %w{ATM UNKNOWN UNKNOWNPAYEE CHECK ONLINETRANSFER SHAREDRAFT FEDCLEARINGDEBIT}
    end

    it "should be independent for paypal transfers" do
      assert_edit_independently %w{PAYPALINSTXFER PAYPALTRANSFER PAYPALECHECK}
    end

    it "should be intependent for debit card transactions" do
      assert_edit_independently %w{POSDEB DBTCRD 1POSDEB DEBIT DDAPOINTOFSALEDEBIT}
    end

    it "should be independent for Bank of America deposits" do
      assert_edit_independently %w{INTERNETDEPOSITBANKOFAMERIC BKOFAMERICAATMDEPOSITBANKOFAMERICABREACA}
    end

    it "should not be independent for ATM withdrawals" do
      assert_not_edit_independently %w{ATMWITHDRAWAL 123ATMWITHDRAWAL ATMWITHDRAWAL123}
    end

    it "should be independent for ATM withdrawals with type DEBIT" do
      @txaction.txaction_type_id = 2 # "DEBIT"
      assert_edit_independently %w{ATMWITHDRAWAL 123ATMWITHDRAWAL ATMWITHDRAWAL123}
    end

    it "should be independent for RBC WWW transfers and payments" do
      assert_edit_independently %w{WWWTRANSFER WWWPAYMENT}
    end

    it "should be independent for UFB Direct transfers" do
      assert_edit_independently %w{TRANSFERIN TRANSFEROUT}
    end

    it "should be independent for electronic transfers in Brazil" do
      assert_edit_independently %w{DECCENVSACADO}
    end

    it "should be independant for President's Choice Canada ATM withdrawals and other transfers" do
      assert_edit_independently %w{TRANSFEROUTTRANSFEROUT}
    end

    it "should be independent for Citibank checking debit cards with no memo yet" do
      # fbz 62507
      assert_edit_independently %w{DEBITPIN}
    end

    it "should be independent for PayPal instant transfers from BofA accounts" do
      assert_edit_independently %w{PAYPALDESINSTXFER}
    end

    it "should not allow other transactions to be edited independently" do
      assert_not_edit_independently %w{
        UNKNOWNMERCHANT
        ELECTRONICBUGALOO
        INTERNET
        PAYPALECHECK123
        DEPOSITINTOSOMEACCOUNT
        CROWD
      }
    end

  end

  describe "Doing operations on sets of transactions" do
    before do
      2.times { Account.make(:user => current_user) }
      @accounts = current_user.accounts
      @account = @accounts.first

      @txactions = %w[2007-09-25 2007-08-25 2007-01-19 2006-08-19].inject([]) do |txs, date|
        date = Time.parse(date)
        txs << Txaction.make(:account => @accounts[0], :date_posted => date) <<
               Txaction.make(:account => @accounts[1], :date_posted => 1.month.since(date))
      end
    end

    it "should find transactions within a date range" do
      Txaction.with_options :user => current_user, :start_date => '2007-08-01', :end_date => '2007-10-01' do |tx|
        tx.find_within_dates(@account).should have(2).items
      end
    end
  end

  describe "A cash transaction" do
    it "should allow simple calculations in amount" do
      Txaction.calculate_amount("$5").should eql("5.00")
      Txaction.calculate_amount("$5 + 2.50").should eql("7.50")
      Txaction.calculate_amount("($5+$3)/2").should eql("4.00")
      Txaction.calculate_amount("$5+illegal_input").should eql("5.00")
      Txaction.calculate_amount("illegal_input").should eql("0.00")
    end
  end

  describe 'in a manual account' do
    before do
      @account  = Account.make(:manual)
      @txaction = Txaction.new(:account => @account)
    end

    it "should be a manual txaction" do
      @txaction.should be_a_manual_txaction
    end
  end

  describe 'in a cash account' do
    before do
      @account  = Account.make(:manual)
      @txaction = Txaction.new(:account => @account)
    end

    it "should be a manual txaction" do
      @txaction.should be_a_manual_txaction
    end
  end

  describe "deleting a Txaction" do
    before do
      @account = Account.make(:manual, :user => current_user)
      @txaction = Txaction.make(:account => @account, :amount => 1)
    end

    it "should delete a txaction outright on destroy" do
      lambda { @txaction.destroy }.
        should change { Txaction.find_by_id(@txaction.id) }.
                from(@txaction).to(nil)
    end

    it "should sever any transfer buddy links" do
      transfer_buddy = Txaction.make(:account => @account, :amount => -1)
      @txaction.set_transfer_buddy!(transfer_buddy)
      transfer_buddy.transfer_buddy.should == @txaction
      @txaction.transfer_buddy.should == transfer_buddy
      @txaction.destroy
      transfer_buddy.reload
      transfer_buddy.transfer_buddy.should be_nil
      @txaction.transfer_txaction_id.should be_nil
    end
  end

  describe "safely deleting a Txaction" do
    before do
      @account = Account.make(:manual, :user => current_user)
      @txaction = Txaction.make(:account => @account)
    end

    it "does not actually destroy the Txaction" do
      @txaction.safe_delete
      Txaction.exists?(@txaction.id).should be_true
    end

    it "marks the Txaction as deleted" do
      @txaction.safe_delete
      @txaction.should be_deleted
    end
  end

  describe "change status class method" do
    before do
      @account = Account.make(:user => current_user)
      @txaction = Txaction.make(:account => @account, :amount => 1)
      @txaction_with_disabled_dup = Txaction.make(:account => @account, :amount => 2)
      @disabled_dup_txaction = Txaction.make(:disabled, :wesabe_txid => @txaction_with_disabled_dup.wesabe_txid, :account => @account, :amount => 2)
    end

    it "should set the status of a disabled txaction to DISABLED" do
      id = @txaction.id
      @txaction.status.should == Constants::Status::ACTIVE
      Txaction.change_status([@txaction], Constants::Status::DISABLED)
      Txaction.find(id).status.should == Constants::Status::DISABLED
    end

    it "should not disable a txaction that has a disabled duplicate" do
      id = @txaction_with_disabled_dup.id
      @txaction_with_disabled_dup.status.should == Constants::Status::ACTIVE
      Txaction.change_status([@txaction_with_disabled_dup], Constants::Status::DISABLED)
      Txaction.find(id).status.should == Constants::Status::ACTIVE
    end
  end

  describe "transfers" do
    include TxactionSpecHelper

    before do
      @fi = FinancialInst.make
      @account  = Account.make(:user => current_user, :financial_inst => @fi)
      @account2 = Account.make(:user => current_user, :financial_inst => @fi)
      @account3 = Account.make(:user => current_user, :financial_inst => @fi,
        :account_type_id => AccountType::CREDITLINE)
    end

    it "find each other when brand new" do
      tx1 = create_and_attach_txaction(:amount =>  12.34, :account => @account)
      tx2 = create_and_attach_txaction(:amount => -12.34, :account => @account2)

      tx1.reload.transfer_buddy.should == tx2
      tx2.reload.transfer_buddy.should == tx1
    end

    it "should find each other when brand new" do
      tx1 = create_and_attach_txaction
      tx2 = create_and_attach_txaction(:debit => true)

      tx1.reload
      tx2.reload

      tx1.transfer_buddy.should == tx2
      tx2.transfer_buddy.should == tx1
    end

    it "should just pick a dupe and go with it" do
      tx1 = create_and_attach_txaction
      tx2 = create_and_attach_txaction(:debit => true, :filtered_name => 'FOO')
      tx3 = create_and_attach_txaction(:debit => true, :filtered_name => 'FOO')

      tx1.reload
      tx2.reload

      [tx2, tx3].should include(tx1.transfer_buddy)
    end

    it "should do the right thing for outliers" do
      tx1 = create_and_attach_txaction
      tx2 = create_and_attach_txaction(:debit => true, :filtered_name => 'foo')
      tx3 = create_and_attach_txaction(:debit => true, :filtered_name => 'bar', :date_posted => 3.days.ago)

      tx1.reload
      tx2.reload

      tx1.transfer_buddy.should == tx2
      tx2.transfer_buddy.should == tx1
    end

    it "should give up when there's no good choice" do
      tx1 = create_and_attach_txaction
      tx2 = create_and_attach_txaction(:debit => true, :filtered_name => 'foo')
      tx3 = create_and_attach_txaction(:debit => true, :filtered_name => 'bar')

      tx1.reload
      tx2.reload
      tx3.reload

      tx1.transfer_buddy.should be_nil
      tx2.transfer_buddy.should be_nil
      tx3.transfer_buddy.should be_nil
    end

    it "should be smart with names" do
      tx1 = create_and_attach_txaction
      tx2 = create_and_attach_txaction(:debit => true, :filtered_name => 'TRANSFER')
      tx3 = create_and_attach_txaction(:debit => true, :filtered_name => 'bar')

      tx1.reload
      tx2.reload

      tx1.transfer_buddy.should == tx2
      tx2.transfer_buddy.should == tx1
    end

    describe "when the transfer reference is stale" do
      before do
        @tx1 = Txaction.make(:account => @account)
        @tx1.update_attribute(:transfer_txaction_id, 10101010)
        @tx1.reload
      end

      it "should not count as a paired transfer" do
        @tx1.should_not be_a_paired_transfer
      end
    end

    it "should not match lines of credit" do
      tx1 = create_and_attach_txaction
      tx2 = create_and_attach_txaction(:account => @account3, :debit => true)

      tx1.transfer_buddy.should be_nil
      tx2.transfer_buddy.should be_nil
    end

    it "should not automatically mark transactions more than a week apart" do
      tx1 = create_and_attach_txaction
      tx2 = create_and_attach_txaction(:debit => true, :date_posted => Date.today + 12.days)

      tx1.reload
      tx2.reload

      tx1.transfer_buddy.should be_nil
      tx2.transfer_buddy.should be_nil
    end

    it "should allow manual marking of transactions more than a week apart" do
      tx1 = create_and_attach_txaction
      tx2 = create_and_attach_txaction(:debit => true, :date_posted => Date.today + 12.days)

      tx1.find_all_matching_transfers.should include(tx2)
      tx2.find_all_matching_transfers.should include(tx1)
    end
  end

  describe "attachments" do
    before do
      @txaction_that_never_had_attachments = Txaction.new(:attachment_ids => nil)
      @txaction_with_attachments = Txaction.new(:attachment_ids => [1,2,3])
      @txaction_that_once_had_attachments = Txaction.new(:attachment_ids => [])
    end

    it "should return true if a txaction has an attachment" do
      @txaction_with_attachments.has_attachment?.should be_true
    end

    it "should return false if a txaction has never had an attachment" do
      @txaction_that_never_had_attachments.has_attachment?.should be_false
    end

    it "should return false if a txaction once had attachments" do
      @txaction_that_once_had_attachments.has_attachment?.should be_false
    end

    it "should return true if a set of txactions has attachments" do
      Txaction.has_attachments?([@txaction_that_never_had_attachments, @txaction_with_attachments]).should be_true
    end

    it "should return false if a set of txactions does not have attachments" do
      Txaction.has_attachments?([@txaction_that_never_had_attachments, @txaction_that_once_had_attachments]).should be_false
    end
  end

  describe "dealing with splits" do
    it_should_behave_like 'it has a logged-in user'

    before do
      clear_currency_exchange_rates
      CurrencyExchangeRate.create(:currency => "GBP", :rate => "0.5", :date => Time.now)
      @usd_account = Account.make(:user => current_user, :currency => "USD")
      @gbp_account = Account.make(:user => current_user, :currency => "GBP")
      @usd_txaction = Txaction.make(:account => @usd_account, :amount => -100)
      @gbp_txaction = Txaction.make(:account => @gbp_account, :amount => -100)
      @usd_txaction.tag_with("foo bar:10 baz:20")
      @gbp_txaction.tag_with("foo bar:10 baz:20")
    end

    it "should return the split amount when a tag is provided" do
      @usd_txaction.amount(:tag => "foo").should be_close(-100.0, 0.01)
      @usd_txaction.amount(:tag => "bar").should be_close(-10.0, 0.01)
      @usd_txaction.amount(:tag => "baz").should be_close(-20.0, 0.01)
    end

    it "should return the usd_split amount when a tag is provided" do
      @gbp_txaction.usd_amount(:tag => "foo").should be_close(-200.0, 0.01)
      @gbp_txaction.usd_amount(:tag => "bar").should be_close(-20.0, 0.01)
      @gbp_txaction.usd_amount(:tag => "baz").should be_close(-40.0, 0.01)
    end

    it "should sum a list of txactions by tag" do
      txactions = [@usd_txaction, @gbp_txaction]
      Txaction.sum_in_target_currency(txactions, "USD").should be_close(-300.0, 0.01)
      Txaction.sum_in_target_currency(txactions, "USD", "foo").should be_close(-300.0, 0.01)
      Txaction.sum_in_target_currency(txactions, "GBP", "bar").should be_close(-15.0, 0.01)
      Txaction.sum_in_target_currency(txactions, "USD", "baz").should be_close(-60.0, 0.01)
    end
  end

  describe "find_others_from_merchant method" do
    it_should_behave_like 'it has a logged-in user'

    before do
      @account = Account.make(:user => current_user)
      @merchant = Merchant.make
      @tx  = @account.txactions.make(:merchant => @merchant, :amount => -2.95)
      @new = @account.txactions.make(:merchant => @merchant, :amount => -2.95)
    end

    it "should return [] if merchant is not set" do
      @tx.merchant = nil
      @tx.find_others_from_merchant(current_user).should == []
    end

    it "should return [] if the user has no accounts" do
      current_user.accounts.first.destroy
      @tx.find_others_from_merchant(current_user).should == []
    end

    it "should return txactions that share a merchant and sign with this one" do
      @tx.find_others_from_merchant(current_user).should include(@new)
    end
  end
end