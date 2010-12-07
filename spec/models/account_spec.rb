require 'spec_helper'

describe Account do
  it_should_behave_like "it has a logged-in user"

  describe "creating an Account" do
    before do
      @account = Account.make
    end

    it "should allow currency to be set to a Currency object" do
      currency = Currency.new("USD")
      @account.currency = currency
      @account.save!
      @account.reload
      @account.read_attribute(:currency).should == "USD"
    end
  end

  describe "associations" do
    it_should_behave_like 'it has a logged-in user'

    before do
      @account = Account.make(:user => current_user)
      @account.balance = 0.0
    end

    it "should belong to a financial institution" do
      @account.financial_inst.should == FinancialInst.find(@account.financial_inst_id)
    end

    it "should have many transactions" do
      @tx1, @tx2 = Txaction.make(:account => @account), Txaction.make(:account => @account)
      @account.txactions.should contain_same_elements_as([@tx1, @tx2])
    end

    it "should have many account balances" do
      @ab1, @ab2 = AccountBalance.make(:account => @account), AccountBalance.make(:account => @account)
      @account.account_balances.should include(@ab1)
      @account.account_balances.should include(@ab2)
    end

    it "should return the newest balance as the last balance" do
      @account.account_balances.destroy_all

      yesterday = AccountBalance.make(:balance_date => 1.week.ago, :account_id => @account.id)
      @account.last_balance(true).should == yesterday

      today = AccountBalance.make(:balance_date => 1.day.ago, :account_id => @account.id)
      @account.last_balance(true).should == today
    end

    it "should have and belong to many uploads" do
      @u1 = Upload.make
      @account.uploads << @u1
      @account.uploads.should == [@u1]
    end

  end

  describe "class" do
    it "should provide the last 4 numbers of a given account number" do
      Account.last4("123456789").should == "6789"
    end

    it "should strip any non-word characters before taking the last 4" do
      Account.last4("12-3456-789").should == "6789"
    end

    it "should find the significant digits using the regex, if provided" do
      Account.last4("12-3456-789-S.S000", '(\d{2})S+(\d+)').should == "89000"
    end

    it "should ignore a blank regex" do
      Account.last4("12-3456-789-S.S000", '').should == "S000"
    end

    it "should raise an exception if no groupings are provided in the regex" do
      lambda {
        Account.last4("12-3456-789-S.S000", '\d{2}S+\d+')
      }.should raise_error
    end
  end

  shared_examples_for "a transaction account" do
    it "should return a txaction hooked up to itself" do
      @account.new_txaction.account.should == @account
    end
  end

  shared_examples_for "a manual account" do
    it_should_behave_like 'a transaction account'

    it "should claim to be a manual account" do
      @account.should be_a_manual_account
    end
  end

  describe 'type CASH' do
    before do
      @account = Account.make(:cash)
    end

    it_should_behave_like 'a transaction account'

    it "should claim to be a cash account" do
      @account.should be_a_cash_account
    end

    it "should have no balance" do
      @account.balance.should be_nil
      @account.should_not have_balance
    end

    it "should not have an editable balance" do
      @account.editable_balance?.should be_false
    end

    it "should raise on setting a balance" do
      lambda { @account.balance = 0.0 }.
        should raise_error(ArgumentError, "Cannot set balance on account with type Cash")
    end
  end

  describe 'type MANUAL' do
    before do
      # given
      @account = Account.new(:account_type_id => AccountType::MANUAL)
      @txactions = [mock_model(Txaction, :calculate_balance! => 12.50, :amount => 2.50)]
    end

    it_should_behave_like 'a manual account'

    it "should have a balance" do
      @account.should have_balance
    end

    it "should have an editable balance" do
      @account.editable_balance?.should be_true
    end
  end

  describe 'type CHECKING' do
    before do
      @account = Account.new(:account_type_id => AccountType::CHECKING)
      @new_balance = mock_model(AccountBalance, :balance_date => 6.hours.ago, :balance => 123.45)
      @older_txaction = mock_model(Txaction, :date_posted => 1.day.ago, :calculate_balance! => 130.00)
      @old_balance = mock_model(AccountBalance, :balance_date => 5.days.ago, :balance => 90.00)
    end

    it_should_behave_like 'a transaction account'

    it "should not claim to be a cash account" do
      @account.should_not be_a_cash_account
    end

    it "should not claim to be a manual account" do
      @account.should_not be_a_manual_account
    end
  end

  describe "callbacks" do
    it_should_behave_like 'it has a logged-in user'

    before do
      @account = Account.make(:user => current_user)
    end

    it "should delete an account on destroy" do
      @account.status.should == Constants::Status::ACTIVE
      @account.destroy
      Account.find_by_id(@account.id).should be_nil
    end

    it "should delete txactions on destroy" do
      @tx = Txaction.make(:account => @account)
      @account.destroy
      Txaction.find_by_id(@tx.id).should be_nil
    end

  end

  describe "created by SSU" do
    before do
      # given
      @account_cred = mock_model(AccountCred)
      @accounts = [@account]
      @accounts.stub!(:count).and_return(1)
      @account_cred.stub!(:accounts).and_return(@accounts)
      @account_cred.stub!(:destroy)

      @account = Account.make
      @account.stub!(:account_cred).and_return(@account_cred)
      @account.stub!(:ssu?).and_return(true)
      @job = mock_model(SsuJob)
    end

    it "should set account status to disabled on destroy if its AccountCred has active accounts" do
      # when
      @accounts = [@account, @account]
      @accounts.stub!(:count).and_return(2)
      @account_cred.stub!(:accounts).and_return(@accounts)

      @account.destroy

      # then
      Account.find(@account.id).status.should == Constants::Status::DISABLED
    end

    it "should destroy the account if its AccountCred has only this account" do
      # when
      @account.destroy

      # then
      lambda { Account.find(@account.id) }.should raise_error(ActiveRecord::RecordNotFound)
    end

    it "knows it was newly created if it has one upload and is listed in the job" do
      # when
      uploads = mock(:uploads, :count => 1)
      @account.stub!(:uploads).and_return(uploads)
      @job.stub!(:accounts).and_return([@account])

      # then
      @account.should be_newly_created_by(@job)
    end

    it "knows it was not newly created if it has more than one upload" do
      # when
      uploads = mock(:uploads, :count => 2)
      @account.stub!(:uploads).and_return(uploads)
      @job.stub!(:accounts).and_return([@account])

      # then
      @account.should_not be_newly_created_by(@job)
    end

    it "knows it was not newly created if the job does not list it" do
      # when
      uploads = mock(:uploads, :count => 1)
      @account.stub!(:uploads).and_return(uploads)
      @job.stub!(:accounts).and_return([])

      # then
      @account.should_not be_newly_created_by(@job)
    end

    it "knows it was newly created by a cred if it has one upload and is listed in the cred's job" do
      # when
      uploads = mock(:uploads, :count => 1)
      @account.stub!(:uploads).and_return(uploads)
      @job.stub!(:accounts).and_return([@account])
      @cred = mock_model(AccountCred, :last_job => @job)

      # then
      @account.should be_newly_created_by(@cred)
    end

  end

  describe "guids" do
    before do
      @account = Account.make
    end

    it "should generate a guid when created" do
      @account.guid.should match(/[a-f0-9]{64}/)
    end

    it "should not generate a new guid when edited" do
      lambda {
        @account.update_attribute(:account_number, 1234)
      }.should_not change(@account, :guid)
    end

    it "should not allow duplicate guids to be saved" do
      @second = Account.make
      @second.guid = @account.guid
      lambda { @second.save! }.should raise_error
    end

    it "should be a protected attribute" do
      @second = Account.new(:guid => "abc")
      @second.guid.should_not == "abc"
    end

  end

  describe Account do

    before do
      @account = Account.make
    end

    it "should be able to generate a guid" do
      lambda { @account.send(:generate_guid) }.should change(@account, :guid)
    end

    it "should set account_type_id when account_type is set" do
      @account.account_type = AccountType.find(3)
      @account.account_type_id.should == 3
    end

    it "should provide its financial institution's name" do
      @account.financial_inst = mock_model(FinancialInst, :name => "Citibank")
      @account.financial_inst_name.should == "Citibank"
    end

    it "should provide the current balance" do
      @account.should_receive(:last_balance).with(true).and_return(mock_model(AccountBalance, :balance => 25))
      @account.balance.should == 25
    end

    it "should not provide a balance for cash accounts, which don't have a balance" do
      @account.account_type = AccountType.find_by_raw_name("Cash")
      @account.balance.should be_nil
    end

    it "should know if it is a cash account" do
      @account.account_type = AccountType.find_by_raw_name("Cash")
      @account.should be_cash_account
    end

    it "should know if it is a brokerage account" do
      @account.account_type = AccountType.find_by_raw_name("Brokerage")
      @account.should be_brokerage_account
    end

    it "should delete itself on destroy" do
      @account.save; @account.destroy
      Account.find_by_id(@account.id).should be_nil
    end

    it "should delete account balances on destroy" do
      @account.save
      account_balance = AccountBalance.make(:account => @account)
      AccountBalance.find_by_id(account_balance.id).should_not be_nil
      @account.destroy
      AccountBalance.find_by_id(account_balance.id).should be_nil
    end

    it "should delete associated uploads on destroy if they don't reference other accounts" do
      @account.save
      @account.uploads << [Upload.make, Upload.make]
      @account.uploads.count.should == 2
      @account.destroy
      @account.uploads.count.should == 0
    end

    it "should not delete associated uploads on destroy if they reference other accounts" do
      account1 = Account.make
      account2 = Account.make
      upload1 = Upload.make
      upload2 = Upload.make
      account1.uploads << [upload1]
      account2.uploads << [upload1, upload2]
      account1.uploads.count.should == 1
      account2.uploads.count.should == 2
      account2.destroy
      Upload.find_by_id(upload1.id).should_not be_nil
      Upload.find_by_id(upload2.id).should be_nil
      account1.destroy
      Upload.find_by_id(upload1.id).should be_nil
    end

    it "should provide the last upload it received" do
      @account.save
      upload = Upload.make
      AccountUpload.create(:upload => upload, :account => @account)
      @account.last_upload.should == upload
    end

    describe "negate_balance! method" do
      it "should not error if there is no last balance" do
        lambda { @account.negate_balance! }.should_not raise_error
      end

      it "should set the negate balance flag on the account" do
        lambda { @account.negate_balance! }.should change(@account, :negate_balance?)
      end

      it "should remove the negate balance flag if it is already set" do
        lambda { @account.negate_balance! }.should change(@account, :negate_balance?)
      end

      it "should reverse the balance of the last balance" do
        @account.last_balance = AccountBalance.new(:balance => 10.0)
        @account.negate_balance!
        @account.last_balance.balance.should == -10.0
      end
    end

    describe "transaction disabling" do
      it "disable_txactions_before_date should call change status with a date param" do
        User.current = @account.user
        @txaction_before_date = Txaction.make(:account => @account, :date_posted => Date.parse("05 July 2005"), :amount => 1, :status => Constants::Status::ACTIVE)
        @txaction_after_date = Txaction.make(:account => @account, :date_posted => Date.parse("05 July 2008"), :amount => 1, :status => Constants::Status::ACTIVE)
        @date = Date.parse("01 Jan 2007")
        Txaction.should_receive(:change_status).with(@account.txactions.find_all_by_id(@txaction_before_date.id), Constants::Status::DISABLED)
        @account.disable_txactions_before_date(@date)
      end
    end

    describe "balance" do
      before do
        @account2 = Account.make
      end

      context "setting a balance" do
        it "should cause the balance to to be set" do
          @account2.balance=2.0
          @account2.balance.should == 2.0
        end

        it "should adjust the balance date according to the user's time zone" do
          user = User.make(:time_zone => "Eastern Time (US & Canada)")
          User.stub!(:current).and_return(user)
          time_now = Time.mktime(2010, 1, 17, 20, 46, 0)
          Time.should_receive(:now).any_number_of_times.and_return(time_now)

          @account2.balance = 3.0
          @account2.reload.balance_date.should == time_now.in_time_zone("Eastern Time (US & Canada)")
        end
      end
    end
  end

  describe "currency attribute" do
    before(:each) do
      @account = Account.make
      @usd = Currency.new("USD")
    end

    it "allows assigning with a currency object" do
      @account.currency = @usd
      @account.currency.should == @usd
    end

    it "allows assigning with a string" do
      @account.currency = "USD"
      @account.currency.should == @usd
    end

    it "is not valid if the currency is unknown" do
      @account[:currency] = "---"
      lambda { @account.valid? }.should raise_error(Currency::UnknownCurrencyException)
    end

    it "returns a nil currency if currency is nil" do
      @account.currency = nil
      @account.currency.should be_nil
    end

    it "does not validate if currency is nil" do
      @account.currency = nil
      @account.should have(1).error_on(:currency)
    end
  end

  describe "user-scoped unique id number" do
    before do
      @user = User.make
      @account = Account.make(:user => @user)
      @second_account = Account.make(:user => @user)
    end

    it "should exist as id_for_user" do
      @account.should respond_to(:id_for_user)
    end

    it "should be provided when to_param is called" do
      @account.to_param.should == 1
    end

    it "should be set when the account is saved" do
      @account.id_for_user.should == 1
    end

    it "should increment to be bigger than the biggest id_for_user so far" do
      @second_account.id_for_user.should == 2
    end

    it "should show up in the user's accounts" do
      @user.accounts.should include(@account)
    end

    it "should not change for other accounts when an account is deleted" do
      @account.destroy
      @user.accounts.first.id_for_user.should == 2
    end

    it "should validate an id that is unique for its user" do
      @second_account.should be_valid
    end

    it "should validate the the name is not blank" do
      @account.name = ""
      @account.should_not be_valid

      @account.name = nil
      @account.should_not be_valid
    end

    it "should fix ids that are not unique on validate" do
      @second_account.id_for_user = @account.id_for_user
      @second_account.should_not be_new_record
      @second_account.save!
      @second_account.id_for_user.should == 3
    end

    it "should be a protected attribute" do
      @account = Account.new(:id_for_user => 1)
      @account.id_for_user.should be_nil
    end

  end
end
