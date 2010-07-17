module OFX
  module Builder
    class InvestmentAccountBuilder < StatementBuilder
      attr_accessor :accounts

      def initialize(statement)
        super
        @accounts = []
      end

      def process(element)
        return unless element.include?('INVSTMTRS')

        start_account unless @statement.current_account
        content = element.content
        case element.path
        when /INVSTMTRS\/DTASOF$/
          @statement.current_account.date_as_of = Date.parse(content)
        when /INVSTMTRS\/CURDEF$/
          @statement.current_account.currency = Currency.new(content)
        when /INVACCTFROM\/ACCTID$/
          @statement.current_account.account_number = content # this will be shortened via last4 before saving
        when /INVSTMTRS$/
          end_account
        end
      end

      private

      def start_account
        @statement.current_account = InvestmentAccount.new(:account_type_id => AccountType::INVESTMENT)
      end

      def end_account
        @accounts << @statement.current_account
        @statement.current_account = nil
      end
    end
  end
end
