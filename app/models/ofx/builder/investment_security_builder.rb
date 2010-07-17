module OFX
  module Builder
    class InvestmentSecurityBuilder < StatementBuilder
      attr_accessor :securities

      def initialize(statement)
        super
        @securities = []
      end

      def process(element)
        return unless element.include?('SECLIST')

        start_security unless @security

        content = element.content
        case element.name
        when 'UNIQUEID'
          @security.unique_id = content
        when 'UNIQUEIDTYPE'
          @security.unique_id_type = content
        when 'SECNAME'
          @security.name = content
        when 'TICKER'
          @security.ticker = content
        when 'SECINFO'
          end_security
        else
          add_unrecognized_element(element)
        end
      end

      private

      def start_security
        @security = InvestmentSecurity.new
      end

      def end_security
        @securities << @security
        @security = nil
      end
    end
  end
end