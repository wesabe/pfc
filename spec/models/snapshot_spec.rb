require 'spec_helper'


describe Snapshot do
  before do
    @snapshot = described_class.make
    @user = @snapshot.user
    User.current = @user
  end

  after do
    @snapshot.destroy
  end

  describe 'round-tripping a user' do
    def export_and_delete_user_and_reimport
      @snapshot.build

      # destroying the user will kill the snapshot, so we move it out of the way first
      intermediate_snapshot_file = @snapshot.archive.dirname + "#{$$}.zip"
      @snapshot.archive.rename(intermediate_snapshot_file)
      user = User.find(@user.id)
      user.account_key = @user.account_key
      user.destroy
      FinancialInst.delete_all
      InvestmentSecurity.delete_all
      Attachment.destroy_all
      InboxAttachment.destroy_all
      intermediate_snapshot_file.rename(@snapshot.archive)

      @snapshot.import
    end

    def imported_amts
      AccountMerchantTagStat.first(:conditions => {:account_key => imported_user.account_key})
    end

    def imported_merchant_user
      MerchantUser.first(:conditions => {:user_id => imported_user.id})
    end

    def imported_taggings
      imported_txaction.taggings
    end

    def imported_txaction
      imported_txactions.first
    end

    def imported_txactions
      imported_account.txactions
    end

    def imported_position
      imported_positions.first
    end

    def imported_positions
      imported_account.all_positions
    end

    def imported_financial_institution
      imported_account.financial_inst
    end

    def imported_other_balance
      imported_other_balances.first
    end

    def imported_other_balances
      imported_balance.other_balances
    end

    def imported_balance
      imported_balances.first
    end

    def imported_balances
      imported_account.balances
    end

    def imported_account_balances
      imported_account.account_balances.find(:all, :order => 'balance_date ASC')
    end

    def imported_attachments
      imported_txaction.attachments
    end

    def imported_attachment
      imported_attachments.first
    end

    def imported_inbox_attachment
      imported_inbox_attachments.first
    end

    def imported_inbox_attachments
      InboxAttachment.all(:conditions => {:account_key => imported_user.account_key})
    end

    def imported_account
      imported_accounts.first
    end

    def imported_accounts
      imported_user.accounts
    end

    def imported_targets
      imported_user.targets
    end

    def imported_target
      imported_user.targets.first
    end

    def imported_user
      @imported_user ||= export_and_delete_user_and_reimport
    end

    it 'creates a new user' do
      lambda { imported_user }.should change { User.maximum(:id) }
    end

    it 'preserves the email address' do
      imported_user.email.should == @user.email
    end

    it 'sets the password to "changeme!"' do
      assert imported_user.valid_password?('changeme!')
    end

    it 'preserves the name' do
      imported_user.name.should == @user.name
    end

    it 'preserves the postal code' do
      imported_user.postal_code.should == @user.postal_code
    end

    it 'preserves the country' do
      imported_user.country.should == Country.us
    end

    it 'preserves the lack of country' do
      @user.country = nil
      @user.save!
      imported_user.country.should be_nil
    end

    it 'preserves the default currency' do
      imported_user.default_currency.should == Currency.usd
    end

    context 'with a default currency other than USD' do
      before do
        @user.update_attribute :default_currency, 'CAD'
      end

      it 'preserves the default currency' do
        imported_user.default_currency.should == Currency.new('CAD')
      end
    end

    it 'preserves the time zone' do
      imported_user.time_zone.should == @user.time_zone
    end

    it 'gives the user an account key' do
      imported_user.account_key.should_not be_blank
    end

    it 'preserves user preferences' do
      @user.preferences.write(:snapshot_preserves_preferences, true)
      @user.preferences.save!
      imported_user.preferences.read(:snapshot_preserves_preferences).should be_true
    end

    context 'with no accounts' do
      it 'does not import any accounts' do
        imported_accounts.should be_empty
      end
    end

    context 'with an account' do
      before do
        @account = Account.make(:checking, :user => @user)
      end

      it 'imports a single account' do
        imported_accounts.should have(1).item
      end

      it 'preserves the account name' do
        imported_account.name.should == @account.name
      end

      it 'preserves the currency' do
        imported_account.currency.should == @account.currency
      end

      it 'preserves the account number' do
        imported_account.account_number.should == @account.account_number
      end

      it 'preserves the account number hash' do
        imported_account.account_number_hash.should == @account.account_number_hash
      end

      it 'preserves the account type' do
        imported_account.account_type.should == @account.account_type
      end

      it 'preserves the status' do
        imported_account.status.should == @account.status
      end

      context 'when the account is archived' do
        before do
          @account.status = Constants::Status::ARCHIVED
          @account.save!
        end

        it 'preserves the account archival status' do
          account = imported_account
          account.status.should == @account.status
          account.should be_archived
        end
      end

      it 'preserves the negate-balance flag' do
        @account.negate_balance = true
        @account.save!
        imported_account.negate_balance.should == @account.negate_balance
      end

      it 'preserves the id for user' do
        imported_account.id_for_user.should == @account.id_for_user
      end

      it 'preserves the type' do
        @account.type = 'InvestmentAccount'
        @account.save!
        imported_account.type.should == @account.type
      end

      it 'preserves the historical balances' do
        @account.balance = 40
        @account_balance = AccountBalance.create!(:balance => 12, :account => @account, :balance_date => 1.day.ago)
        imported_account.should have(2).account_balances
        imported_account_balances.first.balance.should == @account_balance.balance
        imported_account_balances.first.balance_date.should be_close(@account_balance.balance_date, 1.second)
      end

      it 'does not preserve uploads' do
        AccountUpload.create!(:upload => Upload.make, :account => @account)
        imported_account.uploads.should be_empty
      end

      context 'without a financial institution' do
        before do
          @account.account_type = AccountType.find_by_raw_name('Manual')
          @account.financial_inst = nil
          @account.save!
        end

        it 'imports without a financial institution' do
          imported_account.financial_inst.should be_nil
        end
      end

      context 'with a financial institution' do
        before do
          @financial_inst = @account.financial_inst = FinancialInst.make
          @account.save!
        end

        it 'preserves the financial institution' do
          imported_financial_institution.should_not be_nil
        end

        it 'preserves the financial institution name' do
          imported_financial_institution.name.should == @account.financial_inst.name
        end

        it 'preserves the homepage url' do
          @financial_inst.homepage_url = 'http://myexamplebank.com/'
          @financial_inst.save!
          imported_financial_institution.homepage_url.should == @financial_inst.homepage_url
        end

        it 'preserves the login url' do
          @financial_inst.login_url = 'http://myexamplebank.com/login'
          @financial_inst.save!
          imported_financial_institution.login_url.should == @financial_inst.login_url
        end

        it 'preserves the wesabe id' do
          @financial_inst.wesabe_id = 'us-000999'
          @financial_inst.save!
          imported_financial_institution.wesabe_id.should == @financial_inst.wesabe_id
        end

        it 'preserves the username label' do
          @financial_inst.username_label = 'Login ID'
          @financial_inst.save!
          imported_financial_institution.username_label.should == @financial_inst.username_label
        end

        it 'preserves the password label' do
          @financial_inst.password_label = 'PIN'
          @financial_inst.save!
          imported_financial_institution.password_label.should == @financial_inst.password_label
        end

        it 'preserves the connection type' do
          @financial_inst.connection_type = 'Automatic'
          @financial_inst.save!
          imported_financial_institution.connection_type.should == @financial_inst.connection_type
        end

        it 'preserves the date format' do
          @financial_inst.date_format = 'YYYY-MM-DD'
          @financial_inst.save!
          imported_financial_institution.date_format.should == @financial_inst.date_format
        end

        it 'preserves the good txid flag' do
          @financial_inst.good_txid = true
          @financial_inst.save!
          imported_financial_institution.good_txid.should be_true
        end

        it 'preserves the bad balance flag' do
          @financial_inst.bad_balance = true
          @financial_inst.save!
          imported_financial_institution.bad_balance.should be_true
        end

        it 'uses the imported user as the creating user' do
          imported_financial_institution.creating_user.should == imported_user
        end

        it 'makes it featured' do
          imported_financial_institution.should be_featured
        end

        context 'with a country other than the US' do
          before do
            @financial_inst = @account.financial_inst = FinancialInst.make(:country => Country.find_or_create_by_code('ca'))
            @account.save!
          end

          it 'preserves the non-US country' do
            imported_financial_institution.country.should == Country.find_by_code('ca')
          end
        end

        it 'preserves the timezone' do
          @financial_inst.timezone = 'Fiji'
          @financial_inst.save!
          imported_financial_institution.timezone.should == @financial_inst.timezone
        end

        it 'preserves the date-adjusted flag' do
          @financial_inst.date_adjusted = true
          @financial_inst.save!
          imported_financial_institution.date_adjusted.should be_true
        end

        it 'preserves the account number regex' do
          @financial_inst.account_number_regex = '\d{4}$'
          @financial_inst.save!
          imported_financial_institution.account_number_regex.should == @financial_inst.account_number_regex
        end
      end

      context 'when the account has no txactions' do
        before do
          @account.txactions.each(&:destroy)
        end

        it 'has no txactions' do
          imported_txactions.should be_empty
        end
      end

      context 'when the account has a single txaction' do
        before do
          @account.txactions.each(&:destroy)
          @txaction = Txaction.make(:account => @account)
          @txaction_type = @txaction.txaction_type
        end

        it 'imports a single txaction' do
          imported_txaction.should_not be_nil
        end

        it 'preserves the original date posted' do
          imported_txaction.fi_date_posted.should be_close(@txaction.fi_date_posted, 1.second)
        end

        it 'preserves the user date posted' do
          imported_txaction.date_posted.should be_close(@txaction.date_posted, 1.second)
        end

        it 'preserves the raw name' do
          imported_txaction.raw_name.should == @txaction.raw_name
        end

        it 'preserves the filtered name' do
          imported_txaction.filtered_name.should == @txaction.filtered_name
        end

        it 'preserves the cleaned name' do
          imported_txaction.cleaned_name.should == @txaction.cleaned_name
        end

        it 'preserves the txid' do
          imported_txaction.txid.should == @txaction.txid
        end

        it 'preserves the txaction type' do
          imported_txaction.txaction_type.name.should == @txaction_type.name
          imported_txaction.txaction_type.display_name.should == @txaction_type.display_name
        end

        context 'with a good txid financial institution' do
          before do
            @account.financial_inst = FinancialInst.make(:good_txid => true)
            @account.save!
          end

          it 'preserves the wesabe txid' do
            @txaction.wesabe_txid = ActiveSupport::SecureRandom.hex(8)
            @txaction.save!
            imported_txaction.wesabe_txid.should == @txaction.wesabe_txid
          end
        end

        context 'with a bad txid financial institution' do
          before do
            @account.financial_inst = FinancialInst.make(:good_txid => false)
            @account.save!
          end

          it 'adjusts the wesabe txid to use the new account id' do
            assert imported_txaction.wesabe_txid.starts_with?(imported_account.id.to_s)
          end
        end

        context 'with no attachments' do
          before do
            @txaction.attachments.each(&:destroy)
          end

          it 'imports no attachments' do
            imported_txaction.attachments.should be_empty
          end
        end

        context 'with attachments' do
          before do
            @attachment = Attachment.make
            @path = Pathname(@attachment.filepath)
            @path.dirname.mkpath
            FileUtils.touch(@path)
            @txaction.attach(@attachment)
            @txaction.save!
          end

          it 'imports the attachment' do
            imported_attachment.should_not be_nil
          end

          it 'preserves the attachment guid' do
            imported_attachment.guid.should == @attachment.guid
          end

          it 'preserves the attachment description' do
            imported_attachment.description.should == @attachment.description
          end

          it 'preserves the attachment filename' do
            imported_attachment.filename.should == @attachment.filename
          end

          it 'preserves the attachment content type' do
            imported_attachment.content_type.should == @attachment.content_type
          end

          it 'preserves the attachment size' do
            imported_attachment.size.should == @attachment.size
          end

          it 'copies the file data over' do
            @path.open('w') {|f| f << 'omg an attachment' }
            imported_attachment.read.should == 'omg an attachment'
          end
        end

        it 'preserves the lack of merchant' do
          @txaction.merchant = nil
          @txaction.save!
          imported_txaction.merchant.should be_nil
        end

        it 'preserves the merchant' do
          @txaction.merchant = Merchant.find_or_create_by_name('Starbucks')
          @txaction.save!
          imported_txaction.merchant.should == @txaction.merchant
        end

        it 'preserves the memo' do
          @txaction.memo = 'flight to thailand'
          @txaction.save!
          imported_txaction.memo.should == @txaction.memo
        end

        it 'preserves the amount' do
          @txaction.amount = 22.34
          @txaction.save!
          imported_txaction.amount.should == @txaction.amount
        end

        it 'preserves the usd_amount' do
          @txaction.usd_amount = 22.34
          @txaction.save!
          imported_txaction.usd_amount.should == @txaction.usd_amount
        end

        it 'preserves the sequence' do
          @txaction.sequence = 5
          @txaction.save!
          imported_txaction.sequence.should == @txaction.sequence
        end

        it 'preserves the lack of check number' do
          @txaction.check_num = nil
          @txaction.save!
          imported_txaction.check_num.should be_nil
        end

        it 'preserves the check number' do
          @txaction.check_num = '12345'
          @txaction.save!
          imported_txaction.check_num.should == @txaction.check_num
        end

        it 'preserves the memo' do
          @txaction.memo = 'memomemo'
          @txaction.save!
          imported_txaction.memo.should == @txaction.memo
        end

        it 'preserves the note' do
          @txaction.note = 'notenote'
          @txaction.save!
          imported_txaction.note.should == @txaction.note
        end

        it 'preserves the lack of transfer' do
          @txaction.clear_transfer_buddy!
          imported_txaction.should_not be_a_transfer
        end

        it 'preserves unpaired transfers' do
          @txaction.mark_as_unpaired_transfer!
          imported_txaction.should be_a_transfer
          imported_txaction.should_not be_a_paired_transfer
        end

        it 'preserves paired transfers' do
          transfer = Txaction.make(
            :account => Account.make(:user => @user),
            :amount => -999)
          @txaction.set_transfer_buddy!(transfer)
          imported_txaction.should be_a_transfer
          imported_txaction.should be_a_paired_transfer
          imported_txaction.transfer_buddy.amount.should == -999
        end

        it 'marks transfers with invalid pairs as unpaired transfers' do
          @txaction.transfer_txaction_id = 82828
          @txaction.save!
          imported_txaction.should be_a_transfer
          imported_txaction.should_not be_a_paired_transfer
        end

        context 'with no taggings' do
          it 'imports no taggings' do
            imported_taggings.should be_empty
          end
        end

        context 'with a single non-split tagging' do
          before do
            @txaction.tag_with('food')
          end

          it 'imports a single tagging' do
            imported_taggings.should have(1).item
          end

          it 'imports the right tag' do
            imported_taggings.first.tag.should == Tag.find_by_name('food')
          end

          it 'does not include a split amount' do
            imported_taggings.first.split_amount.should be_nil
          end

          it 'does not include a USD split amount' do
            imported_taggings.first.usd_split_amount.should be_nil
          end
        end

        context 'with a single split tagging' do
          before do
            @txaction.tag_with('food:1')
          end

          it 'imports the right tag' do
            imported_taggings.first.tag.should == @txaction.taggings.first.tag
          end

          it 'includes a split amount' do
            imported_taggings.first.split_amount.should == @txaction.taggings.first.split_amount
          end

          it 'includes a USD split amount' do
            imported_taggings.first.usd_split_amount.should == @txaction.taggings.first.usd_split_amount
          end
        end
      end

      context 'with no account merchant tag stats' do
        it 'does not import any' do
          AccountMerchantTagStat.count(:conditions => {:account_key => @user.account_key}).should == 0
        end
      end

      context 'with an account merchant tag stat' do
        before do
          @amts = AccountMerchantTagStat.make(:account_key => @user.account_key)
          @merchant = @amts.merchant
          @tag = @amts.tag
        end

        it 'imports one' do
          imported_amts.should_not be_nil
        end

        it 'preserves the merchant' do
          imported_amts.merchant.name.should == @merchant.name
        end

        it 'preserves the tag' do
          imported_amts.tag.name.should == @tag.name
        end

        it 'preserves the sign' do
          imported_amts.sign.should == @amts.sign
        end

        it 'preserves the count' do
          @amts.update_attribute :count, 42
          imported_amts.count.should == @amts.count
        end

        it 'preserves the forced flag' do
          @amts.update_attribute :forced, true
          imported_amts.should be_forced
        end
      end

      context 'with no merchant links' do
        it 'does not import any' do
          MerchantUser.count(:conditions => {:user_id => @user.id}).should == 0
        end
      end

      context 'with a merchant link' do
        before do
          @mu = MerchantUser.make(:user => @user)
          @merchant = @mu.merchant
        end

        it 'imports it' do
          imported_merchant_user.should_not be_nil
        end

        it 'preserves the merchant' do
          imported_merchant_user.merchant.name.should == @merchant.name
        end

        it 'preserves the sign' do
          imported_merchant_user.sign.should == @mu.sign
        end

        it 'preserves the autotags disabled flag' do
          @mu.update_attribute :autotags_disabled, true
          imported_merchant_user.autotags_disabled.should be_true
        end
      end
    end

    context 'with a cash account' do
      before do
        @account = Account.make(:cash, :user => @user)
      end

      context 'with a transaction' do
        before do
          # the txaction_type_id column is non-nullalbe, but defaults to 0. bleh
          @txaction = Txaction.make(:account => @account)
          Txaction.update_all({:txaction_type_id => 0}, {:id => @txaction.id})
        end

        it 'preserves the nil transaction type' do
          imported_txaction.txaction_type.should be_nil
        end
      end
    end

    context 'with an investment account' do
      before do
        @account = InvestmentAccount.make(:user => @user)
      end

      it 'imports a single account' do
        imported_accounts.should have(1).item
      end

      it 'preserves the type' do
        imported_account.should be_an(InvestmentAccount)
      end

      context 'with no investment transactions' do
        it 'does not import investment transactions' do
          imported_txactions.should be_empty
        end
      end

      context 'with an investment transaction' do
        before do
          @txaction = InvestmentTxaction.make(:account => @account)
          @txaction.account # ensure the association is loaded since some accessors need it later
          @security = @txaction.investment_security
        end

        it 'imports the transaction' do
          imported_txactions.should have(1).item
        end

        it 'ignores the upload' do
          imported_txaction.upload.should be_nil
        end

        it 'preserves the txid' do
          imported_txaction.txid.should == @txaction.txid
        end

        it 'does not preserve the wesabe txid' do
          imported_txaction.wesabe_txid.should_not == @txaction.wesabe_txid
        end

        it 'preserves the memo' do
          imported_txaction.memo.should == @txaction.memo
        end

        it 'preserves the original trade date' do
          imported_txaction.original_trade_date.should be_close(@txaction.original_trade_date, 1.second)
        end

        it 'preserves the original settle date' do
          imported_txaction.original_settle_date.should be_close(@txaction.original_settle_date, 1.second)
        end

        it 'preserves the trade date' do
          imported_txaction.trade_date.should be_close(@txaction.trade_date, 1.second)
        end

        it 'preserves the settle date' do
          imported_txaction.settle_date.should be_close(@txaction.settle_date, 1.second)
        end

        it 'preserves the units' do
          imported_txaction.units.should == @txaction.units
        end

        it 'preserves the unit price' do
          imported_txaction.unit_price.should == @txaction.unit_price
        end

        it 'preserves the commission' do
          imported_txaction.commission.should == @txaction.commission
        end

        it 'preserves the fees' do
          imported_txaction.fees.should == @txaction.fees
        end

        it 'preserves the withholding' do
          imported_txaction.withholding.should == @txaction.withholding
        end

        it 'preserves the total' do
          imported_txaction.total.should == @txaction.total
        end

        it 'preserves the note' do
          imported_txaction.note.should == @txaction.note
        end

        it 'preserves the sub-account type' do
          imported_txaction.sub_account_type.should == @txaction.sub_account_type
        end

        it 'preserves the sub-account fund' do
          imported_txaction.sub_account_fund.should == @txaction.sub_account_fund
        end

        it 'preserves the buy-sell type' do
          imported_txaction.buy_sell_type.should == @txaction.buy_sell_type
        end

        it 'preserves the income type' do
          imported_txaction.income_type.should == @txaction.income_type
        end

        it 'ignores attachment ids' do
          # the feature was never implemented
          imported_txaction.attachment_ids.should be_nil
        end

        it 'preserves the investment security name' do
          imported_txaction.investment_security.name.should == @security.name
        end

        it 'preserves the investment security ticker' do
          imported_txaction.investment_security.ticker.should == @security.ticker
        end

        it 'preserves the investment security unique id' do
          imported_txaction.investment_security.unique_id.should == @security.unique_id
        end

        it 'preserves the investment security unique id type' do
          imported_txaction.investment_security.unique_id_type.should == @security.unique_id_type
        end

        it 'preserves the investment security fi id' do
          imported_txaction.investment_security.fi_id.should == @security.fi_id
        end

        it 'preserves the investment security rating' do
          imported_txaction.investment_security.rating.should == @security.rating
        end

        it 'preserves the investment security memo' do
          imported_txaction.investment_security.memo.should == @security.memo
        end
      end

      context 'with no investment positions' do
        it 'does not import investment positions' do
          imported_positions.should be_empty
        end
      end

      context 'with an investment position' do
        before do
          @position = InvestmentPosition.make(:account => @account)
          @position.account # ensure the association is loaded since some accessors need it later
          @security = @position.investment_security
        end

        it 'imports an investment position' do
          imported_positions.should have(1).item
        end

        it 'preserves the position security' do
          imported_position.investment_security.unique_id.should == @security.unique_id
        end

        it 'preserves the sub-account type' do
          imported_position.sub_account_type.should == @position.sub_account_type
        end

        it 'ignores the upload' do
          imported_position.upload.should be_nil
        end

        it 'preserves the position type' do
          imported_position.position_type.should == @position.position_type
        end

        it 'preserves the units' do
          imported_position.units.should == @position.units
        end

        it 'preserves the unit price' do
          imported_position.unit_price.should == @position.unit_price
        end

        it 'preserves the market value' do
          imported_position.market_value.should == @position.market_value
        end

        it 'preserves the price date' do
          imported_position.price_date.should be_close(@position.price_date, 1.second)
        end

        it 'preserves the memo' do
          imported_position.memo.should == @position.memo
        end

        it 'preserves the reinvest_dividends' do
          imported_position.reinvest_dividends.should == @position.reinvest_dividends
        end

        it 'preserves the reinvest_capital_gains' do
          imported_position.reinvest_capital_gains.should == @position.reinvest_capital_gains
        end
      end

      context 'with an investment balance' do
        before do
          @balance = InvestmentBalance.make(:account => @account)
          @balance.account # ensure the association is loaded since some accessors need it later
        end

        it 'imports an investment balance' do
          imported_balance.should_not be_nil
        end

        it 'preserves the available cash' do
          imported_balance.avail_cash.should == @balance.avail_cash
        end

        it 'preserves the margin balance' do
          imported_balance.margin_balance.should == @balance.margin_balance
        end

        it 'preserves the short balance' do
          imported_balance.short_balance.should == @balance.short_balance
        end

        it 'preserves the buy power' do
          imported_balance.buy_power.should == @balance.buy_power
        end

        context 'with an other balance' do
          before do
            @other_balance = InvestmentOtherBalance.make(:investment_balance => @balance)
          end

          it 'imports an investment other balance' do
            imported_other_balance.should_not be_nil
          end

          it 'preserves the name' do
            imported_other_balance.name.should == @other_balance.name
          end

          it 'preserves the description' do
            imported_other_balance.description.should == @other_balance.description
          end

          it 'preserves the date' do
            imported_other_balance.date.should be_close(@other_balance.date, 1.second)
          end

          it 'preserves the type' do
            imported_other_balance.type.should == @other_balance.type
          end

          it 'preserves the value' do
            imported_other_balance.value.should == @other_balance.value
          end
        end
      end
    end

    context 'with an unassociated attachment (inbox attachment)' do
      before do
        @inbox_attachment = InboxAttachment.make(:user => @user)
        @attachment = @inbox_attachment.attachment
        @path = Pathname(@attachment.filepath)
        @path.dirname.mkpath
        @path.open('w') {|f| f << 'omg inbox attachment' }
      end

      it 'imports it' do
        imported_inbox_attachment.should_not be_nil
      end

      it 'preserves the attachment data' do
        imported_inbox_attachment.attachment.read.should == 'omg inbox attachment'
      end

      it 'preserves the attachment filename' do
        imported_inbox_attachment.attachment.filename.should == @attachment.filename
      end

      it 'preserves the attachment description' do
        imported_inbox_attachment.attachment.description.should == @attachment.description
      end

      it 'preserves the attachment size' do
        imported_inbox_attachment.attachment.size.should == @attachment.size
      end

      it 'preserves the attachment content type' do
        imported_inbox_attachment.attachment.content_type.should == @attachment.content_type
      end
    end

    context 'with no targets' do
      it 'does not import any targets' do
        imported_targets.should be_empty
      end
    end

    context 'with a target' do
      before do
        @target = Target.make(:user => @user)
      end

      it 'imports the target' do
        imported_targets.should have(1).item
      end

      it 'preserves the tag' do
        imported_target.tag.should == @target.tag
      end

      it 'preserves the amount' do
        imported_target.amount_per_month.should == @target.amount_per_month
      end
    end
  end
end