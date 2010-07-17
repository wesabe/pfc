module OFX
  module Builder
    class InvestmentPositionBuilder < StatementBuilder
      attr_accessor :positions

      def initialize(statement)
        super
        @positions = []
      end

      def process(element)
        return unless element.include?('INVPOSLIST')

        start_position unless @position
        content = element.content

        case element.name
        when 'UNIQUEID'
          @position.investment_security.unique_id = content
        when 'UNIQUEIDTYPE'
          @position.investment_security.unique_id_type = content
        when 'HELDINACCT'
          @position.sub_account_type = content
        when 'POSTYPE'
          @position.position_type = content
        when 'UNITS'
          @position.units = content
        when 'UNITPRICE'
          @position.unit_price = content
        when 'MKTVAL'
          @position.market_value = content
        when 'DTPRICEASOF'
          @position.price_date = Time.parse(content)
        when 'MEMO'
          @position.memo = content
        when 'REINVDIV'
          @position.reinvest_dividends = (content == "Y")
        when 'REINVCG'
          @position.reinvest_capital_gains = (content == "Y")
        when 'INVPOS'
          end_position
        else
          add_unrecognized_element(element)
        end
      end

      private

      def start_position
        @position = InvestmentPosition.new(:account => @statement.current_account)
        @position.investment_security = InvestmentSecurity.new
      end

      def end_position
        @positions << @position
        @position = nil
      end
    end
  end
end