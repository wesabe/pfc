# Formats `Money` instances for display.
class Money::Formatter
  class Options # :nodoc:
    # The currency to use, provides defaults for all the remaining options.
    attr_accessor :currency

    # The `Money` instance we're formatting.
    attr_accessor :money

    # The currency unit to use. Default chosen by currency (e.g. "$" for USD).
    attr_accessor :unit

    # The separator to use between whole and fractional parts.
    # Default chosen by currency (e.g. "." for USD).
    attr_accessor :separator

    # The delimiter to use between thousands places.
    # Default chosen by currency (e.g. "," for USD).
    attr_accessor :delimiter

    # The number of decimal places to include. Default chosen by currency (e.g. 2 for USD).
    attr_accessor :precision

    # If `true`, does not show the currency unit symbol.
    attr_accessor :hide_unit

    # If `true`, does not show the delimiter.
    attr_accessor :hide_delimiter

    # If `true`, prefixes the string by the currency short name (e.g. "USD").
    attr_accessor :show_currency

    # If `true`, wraps negative numbers in parentheses instead of
    # prefixing them with a minus sign.
    attr_accessor :negative_parens

    alias_method :hide_unit?, :hide_unit
    alias_method :hide_delimiter?, :hide_delimiter
    alias_method :show_currency?, :show_currency
    alias_method :negative_parens?, :negative_parens

    def initialize(formatter, money, options)
      @currency         = Currency.new(money.currency)
      @money            = money
      @unit             = options[:unit] || currency.unit
      @separator        = options[:separator] || currency.separator
      @delimiter        = options[:delimiter] || currency.delimiter
      @precision        = options[:precision] || currency.decimal_places
      @negative_parens  = options[:negative_parens]
      @hide_unit        = options[:hide_unit] || options[:as_decimal]
      @hide_delimiter   = options[:hide_delimiter] || options[:as_decimal]
      @show_currency    = options[:show_currency]
    end
  end

  # Formats `money` according to the options set on this formatter.
  #
  #     no_decimals = Money::Formatter.new(:precision => 0)
  #     no_decimals.format(Money.new(5, 'USD', Date.today)) # => "$5"
  #
  # @return [String]
  #   The string representation of `money`.
  def format(money)
    options = Options.new(self, money, @options)
    result = generate_number(money, options)
    result = add_delimiter(result, options)
    result = add_currency_unit(result, options)
    result = add_sign(result, options)
    result = add_currency_name(result, options)
  end

  # Formats a `Money` according to the given `options`.
  #
  # @see Money::Formatter#format
  def self.format(money, options={})
    new(options).format(money)
  end

private

  def currency
    @currency ||= Currency.new(money.currency)
  end

  def initialize(options={})
    @options = options
  end

  def generate_number(money, options)
    number = ((Float(money.amount.abs) * (10 ** options.precision)).round.to_f / (10 ** options.precision))
    ("%01.#{options.precision}f" % number).sub('.', options.separator)
  end

  def add_delimiter(amount_string, options)
    return amount_string if options.hide_delimiter?
    begin
      parts = amount_string.to_s.split(options.separator)
      parts[0].gsub!(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1#{options.delimiter}")
      parts.join options.separator
    rescue
      amount_string
    end
  end

  def add_currency_unit(amount_string, options)
    return amount_string if options.hide_unit?
    return options.unit + amount_string
  end

  def add_currency_name(amount_string, options)
    return amount_string unless options.show_currency?
    return "#{options.currency.name} #{amount_string}"
  end

  def add_sign(amount_string, options)
    return amount_string if options.money.amount >= 0
    return options.negative_parens? ? "(#{amount_string})" : "-#{amount_string}"
  end
end
