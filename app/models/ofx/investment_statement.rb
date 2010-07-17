module OFX
  class InvestmentStatement
    attr_accessor :current_account # the account we're currently processing
    attr_accessor :current_balance

    def initialize(xml)
      @account_builder = OFX::Builder::InvestmentAccountBuilder.new(self)
      @txaction_builder = OFX::Builder::InvestmentTxactionBuilder.new(self)
      @security_builder = OFX::Builder::InvestmentSecurityBuilder.new(self)
      @position_builder = OFX::Builder::InvestmentPositionBuilder.new(self)
      @balance_builder  = OFX::Builder::InvestmentBalanceBuilder.new(self)
      @other_balance_builder = OFX::Builder::InvestmentOtherBalanceBuilder.new(self)

      @builders = [@account_builder, @txaction_builder, @security_builder,
                   @position_builder, @balance_builder, @other_balance_builder]

      OFX::Parser.parse(xml) do |element|
        @builders.each {|b| b.process(element) }
      end
    end

    def self.import(upload)
      statement = new(upload.converted_statement)
      statement.save!(upload)
      return statement
    end

    def to_s
      @builders.inspect
    end

    def unrecognized_elements
      @builders.map(&:unrecognized_elements).flatten
    end

    # save the statement; associate and saves various parts of the statement
    def save!(upload)
      InvestmentTxaction.transaction do
        accounts.each do |a|
          a.account_key = upload.account_key
          a.financial_inst_id = upload.fi_id
          if upload.account_cred_id
            # associate account with account cred
            a.account_cred_id = upload.account_cred_id
          end
        end
        self.securities = InvestmentSecurity.find_or_create(securities)
        txactions.each do |t|
          t.account = InvestmentAccount.find_or_create(t.account)
          t.upload = upload
          t.save # don't raise exception on validation error because we don't save it if it exists
        end
        positions.each do |p|
          p.account = InvestmentAccount.find_or_create(p.account)
          p.upload = upload
          p.save!
        end
        balances.each do |b|
          b.account = InvestmentAccount.find_or_create(b.account)
          b.date = b.account.date_as_of
          b.upload = upload
          b.save!
        end
        other_balances.each do |b|
          b.save!
        end
        # make sure the accounts and account_uploads are saved, which might not be the case if there are no txactions
        accounts.each do |a|
          a = InvestmentAccount.find_or_create(a)
          # associate the upload with the account
          a.uploads << upload unless a.uploads.include?(upload)
        end
      end
    end

    def accounts
      @account_builder.accounts
    end

    def txactions
      @txaction_builder.txactions
    end

    def txactions=(txactions)
      @txaction_builder.txactions = txactions
    end

    def securities
      @security_builder.securities
    end

    # update securities with database-associated securities
    def securities=(securities)
      @security_builder.securities = securities

      # update positions and txactions to point to the updated securities
      securities_lookup = Hash[*securities.collect {|s| [s.unique_id, s] }.flatten]

      (positions + txactions).each do |item|
        if item.investment_security && security = securities_lookup[item.investment_security.unique_id]
          item.investment_security = security
        end
      end
    end

    def positions
      @position_builder.positions
    end

    def positions=(positions)
      @position_builder.positions = positions
    end

    def balances
      @balance_builder.balances
    end

    def balances=(balances)
      @balance_builder.balances = balances
    end

    def other_balances
      @other_balance_builder.other_balances
    end

    def other_balances=(other_balances)
      @other_balance_builder.other_balances = other_balances
    end
  end
end
