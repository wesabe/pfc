require 'spec_helper'

describe OFX2Importer do
  before do
    @fi = FinancialInst.make(:name => "TD Canada Trust")
    @upload = Upload.make(:financial_inst => @fi)
    @user = User.make
    @upload.user_id = @user.id
    @upload.account_key = @user.account_key
  end

  describe ".generate_account_name" do
    describe "given a known account type" do
      before do
        @type = AccountType.find_by_raw_name('CHECKING')
      end

      it "uses the format 'Financial Institution Name - Account Type'" do
        OFX2Importer.generate_account_name(@upload, @fi, @type).
          should == "TD Canada Trust - Checking"
      end
    end

    describe "given an UNKNOWN account type" do
      before do
        @type = AccountType.find_by_raw_name('UNKNOWN')
      end

      it "omits the type from the generated name" do
        OFX2Importer.generate_account_name(@upload, @fi, @type).
          should == "TD Canada Trust"
      end
    end
  end

  describe "get_account method" do
    before do
      @stmt_meta = {
        :account_number => "123456.S0001",
        :currency => "USD",
        :account_type => "Checking"
      }
    end

    # create a checking account with the given account number
    def create_account(account_number)
      Account.generate_checking_account!(
        :account_key => @user.account_key,
        :financial_inst => @fi,
        :account_number => account_number)
    end

    it "should create an account if a matching one is not found" do
      Account.delete_all
      lambda {
        OFX2Importer.get_account(@upload, @stmt_meta)
      }.should change(Account, :count).from(0).to(1)
    end

    it "should find an existing account if the last 4 digits match" do
      account = create_account(Account.last4(@stmt_meta[:account_number]))
      OFX2Importer.get_account(@upload, @stmt_meta).should == account
    end

    describe "when the FI has an account number regex" do
      before do
        Account.delete_all
        @fi.update_attribute(:account_number_regex, '(\d{2})S(\d+)$')
      end

      describe "and there's an existing account that matches the last 4" do
        before do
          @account = create_account(Account.last4(@stmt_meta[:account_number]))
        end

        it "should find the account" do
          OFX2Importer.get_account(@upload, @stmt_meta).should == @account
        end

        it "should update the account number on the account with the regex version" do
          lambda {
            OFX2Importer.get_account(@upload, @stmt_meta)
          }.should change { @account.reload.account_number }.from('0001').to('560001')
        end
      end
    end
  end

  describe "fix_txid method" do
    before do
      User.current = @user
      @account = Account.make(:financial_inst => @fi, :account_key => @user.account_key)
      @txaction = Txaction.make(:account => @account, :txid => '123456', :date_posted => Time.parse('20100510'))
      @snap_fi = FinancialInst.make(:wesabe_id => "us-015635")
      @snap_account = Account.make(:financial_inst => @snap_fi, :account_key => @user.account_key)
      @snap_txaction = Txaction.make(:account => @snap_account, :txid => '123456', :date_posted => Time.parse('20100510'))
    end

    it "should not change the txid for a non-Delta Snap account" do
      OFX2Importer.fix_txid(@txaction)
      @txaction.txid.should == '123456'
    end

    it "should change the txid for a Delta Snap account" do
      OFX2Importer.fix_txid(@snap_txaction)
      @snap_txaction.txid.should == '20100510-123456'
    end

    it "should not change the txid for a txaction from a Delta Snap account that has already been updated" do
      @snap_txaction.txid = '20100510-123456'
      OFX2Importer.fix_txid(@snap_txaction)
      @snap_txaction.txid.should == '20100510-123456'
    end
  end
end
