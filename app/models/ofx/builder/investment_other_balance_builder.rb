module OFX
  module Builder
    class InvestmentOtherBalanceBuilder < StatementBuilder
      attr_accessor :other_balances

      def initialize(statement)
        super
        @other_balances = []
      end

      def process(element)
        return unless element.include?('BALLIST')

        start_other_balance unless @other_balance

        content = element.content
        case element.name
        when 'NAME'
          @other_balance.name = content
        when 'DESC'
          @other_balance.description = content
        when 'BALTYPE'
          @other_balance.type = content
        when 'VALUE'
          @other_balance.value = content
        when 'DTASOF'
          @other_balance.date = Time.parse(content)
        when 'BAL'
          end_other_balance
        else
          add_unrecognized_element(element)
        end
      end

      private

      def start_other_balance
        @other_balance = InvestmentOtherBalance.new(:investment_balance => @statement.current_balance)
      end

      def end_other_balance
        @other_balances << @other_balance
        @other_balance = nil
      end
    end
  end
end