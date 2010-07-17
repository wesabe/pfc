module OFX
  module Builder
    class InvestmentTxactionBuilder < StatementBuilder
      attr_accessor :txactions

      def initialize(statement)
        super
        @txactions = []
      end

      def process(element)
        return unless element.include?('INVTRANLIST')

        start_txaction unless @txaction
        content = element.content

        case element.name
        when 'FITID'
          @txaction.txid = content
        when 'DTTRADE'
          @txaction.original_trade_date = @txaction.trade_date = Time.parse(content)
        when 'DTSETTLE'
          @txaction.original_settle_date = @txaction.settle_date = Time.parse(content)
        when 'MEMO'
          @txaction.memo = content
        when 'UNIQUEID'
          @txaction.investment_security ||= InvestmentSecurity.new
          @txaction.investment_security.unique_id = content
        when 'UNIQUEIDTYPE'
          @txaction.investment_security ||= InvestmentSecurity.new
          @txaction.investment_security.unique_id_type = content
        when 'INCOMETYPE'
          @txaction.income_type = content
        when 'UNITS'
          @txaction.units = content
        when 'UNITPRICE'
          @txaction.unit_price = content
        when 'COMMISSION'
          @txaction.commission = content
        when 'TOTAL'
          @txaction.total = content
        when 'SUBACCTSEC'
          @txaction.sub_account_type = content
        when 'SUBACCTFUND'
          @txaction.sub_account_fund = content
        when 'BUYTYPE','SELLTYPE'
          @txaction.buy_sell_type = content
        # possible transaction elements
        when 'BUYDEBT','BUYMF','BUYOPT','BUYOTHER','BUYSTOCK','CLOSUREOPT','INCOME',
             'INVEXPENSE','JRNLFUND','JRNLSEC','MARGININTEREST','REINVEST','RETOFCAP',
             'SELLDEBT','SELLMF','SELLOPT','SELLOTHER','SELLSTOCK','SPLIT','TRANSFER'
          end_txaction
        # known elements we ignore
        when 'DTSTART','DTEND'
        else
          add_unrecognized_element(element)
        end
      end

      private

      def start_txaction
        @txaction = InvestmentTxaction.new(:account => @statement.current_account)
      end

      def end_txaction
        @txactions << @txaction
        @txaction = nil
      end
    end
  end
end
