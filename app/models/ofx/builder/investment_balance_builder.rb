module OFX
  module Builder
    class InvestmentBalanceBuilder < StatementBuilder
      attr_accessor :balances

      def initialize(statement)
        super
        @balances = []
      end

      def process(element)
        return if !element.include?('INVBAL') || element.include?('BALLIST')

        start_balance unless @statement.current_balance
        # since balance is created before the account (because we need DTSERVER), need to set current_account here
        @statement.current_balance.account ||= @statement.current_account

        content = element.content
        case element.name
        when 'AVAILCASH'
          @statement.current_balance.avail_cash = content
        when 'MARGINBALANCE'
          @statement.current_balance.margin_balance = content
        when 'SHORTBALANCE'
          @statement.current_balance.short_balance = content
        when 'BUYPOWER'
          @statement.current_balance.buy_power = content
        when 'INVBAL'
          end_balance
        else
          add_unrecognized_element(element)
        end
      end


      private

      def start_balance
        @statement.current_balance = InvestmentBalance.new
      end

      def end_balance
        @balances << @statement.current_balance
        @statement.current_balance = nil
      end
    end
  end
end
