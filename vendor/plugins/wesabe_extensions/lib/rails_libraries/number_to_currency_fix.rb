# patches number_to_currency to place the currency unit inside the minus sign of negative numbers,
# and optionally allow negative numbers to be surrounded by parentheses
module ActionView
  module Helpers #:nodoc:
    module NumberHelper
      # Formats a +number+ into a currency string. You can customize the format
      # in the +options+ hash.
      # * <tt>:precision</tt>  -  Sets the level of precision, defaults to 2
      # * <tt>:unit</tt>  - Sets the denomination of the currency, defaults to "$"
      # * <tt>:separator</tt>  - Sets the separator between the units, defaults to "."
      # * <tt>:delimiter</tt>  - Sets the thousands delimiter, defaults to ","
      # * <tt>:negative_parens</tt> - Adds parentheses around negative numbers, defaults to false
      #
      #  number_to_currency(1234567890.50)     => $1,234,567,890.50
      #  number_to_currency(1234567890.506)    => $1,234,567,890.51
      #  number_to_currency(1234567890.506, :precision => 3)    => $1,234,567,890.506
      #  number_to_currency(1234567890.50, :unit => "&pound;", :separator => ",", :delimiter => "")
      #     => &pound;1234567890,50
      def number_to_currency(number, options = {})
        options   = options.stringify_keys
        precision = options["precision"] || 2
        unit      = options["unit"] || "$"
        separator = precision > 0 ? options["separator"] || "." : ""
        delimiter = options["delimiter"] || ","
        negative_parens = options["negative_parens"]

        begin
          number_str = number_with_precision(number, :precision => precision, :delimiter => delimiter, :separator => separator)
          number_str.sub!(/^-/,'') # remove minus sign (can't do number.abs because number may be a string)
          if number.to_f < 0
            options["negative_parens"] ? "(#{number_str})" : "-#{number_str}"
          else
            number_str
          end
        rescue
          number
        end
      end
    end
  end
end