# Represents an amount of money of a specific currency on a specific day.
class Money
  # The amount of this `Money`.
  #
  # @return [BigDecimal]
  #   The amount of this `Money`.
  attr_reader :amount

  # The currency this `Money`'s amount is in.
  #
  # @return [String]
  #   The currency of this `Money` (e.g. 'USD').
  attr_reader :currency

  # Converts this `Money` into another with the given currency.
  #
  #     money = Money.new(5, 'USD')
  #     money.convert_to_currency('CAD') # => #<Money amount=5.0 currency="CAD">
  #
  # @param [String] target_currency
  #   The currency string to convert to (e.g. 'GBP').
  # @return [Money]
  #   The converted `Money` instance.
  def convert_to_currency(target_currency, date = Date.today)
    return self if target_currency == currency

    converted_amount = CurrencyExchangeRate.convert(amount, currency, target_currency, date)
    return self.class.new(converted_amount, target_currency)
  end

  # Tests this `Money` for equality with another object.
  #
  # @param [Object] other
  #   The object to test for equality.
  # @return [Boolean]
  #   `true` if `other` is a `Money` and has the same attributes.
  def ==(other)
    other.is_a?(Money) &&
    other.amount == self.amount &&
    other.currency == self.currency
  end

  # Adds two `Money` instances together.
  #
  #     Money.new(1, 'USD') + Money.new(2, 'USD') # => #<Money amount=3.0 currency="USD">
  #
  # Returns a `Money::Bag` if the currencies differ.
  #
  #     Money.new(1, 'USD') + Money.new(2, 'GBP') # => #<Money::Bag @monies={"USD" => #<Money amount=1.0 currency="USD">, "GBP" => #<Money amount=2.0 currency="GBP">}>
  #
  # @param [Money] other
  #   The `Money` instance to add to this one.
  # @return [Money]
  #   A `Money` instance with the sum of the amounts, the same currency.
  # @raise [ArgumentError]
  #   Raised if `other` is not a `Money` or a `Money::Bag`.
  def +(other)
    case other
    when Money
      if self.zero?
        return other
      elsif other.zero?
        return self
      elsif self.currency == other.currency
        return calc { self.amount + other.amount }
      else
        return Money::Bag.new.add(self).add(other)
      end
    when Money::Bag
      return other + self
    else
      raise ArgumentError, "Expected Money instance, got #{other.inspect}"
    end
  end

  # Subtracts `other` from this `Money` instance if they are the same currency.
  #
  #     Money.new(2, 'USD') - Money.new(0.25, 'USD') # => #<Money amount=1.75 currency="USD">
  #
  # @param [Money] other
  #   The `Money` instance to subtract from this one.
  # @return [Money]
  #   A `Money` instance with the difference of the amounts, the same currency.
  # @raise [ArgumentError]
  #   Raised if `other` is not a `Money` or a `Money::Bag`.
  def -(other)
    return self + (-other)
  end

  # Divides this `Money` instance by `divisor` and returns a new `Money`
  # if `divisor` is a number, or a `BigDecimal` if `divisor` is a `Money`
  # of the same currency.
  #
  #     Money.new(2, 'USD') / 2 # => #<Money amount=1.0 currency="USD">
  #     Money.new(4, 'USD') / Money.new(2, 'USD') # => 2.0
  #
  # @param [~to_d, Money] divisor
  #   Anything coercible to a `BigDecimal` or a `Money`.
  # @return [Money, BigDecimal]
  #   A `Money` instance as divided by `divisor`, if `divisor` is a number,
  #   or a number representing the ratio of the `Money` amounts if `divisor`
  #   is a `Money` of the same currency.
  # @raise [ArgumentError]
  #  Raised if `other` cannot be coerced into a `BigDecimal` or is a `Money`
  #  with a different currency.
  def /(divisor)
    if divisor.is_a?(Money)
      if divisor.currency == self.currency
        return amount / divisor.amount
      else
        raise ArgumentError, "Cannot divide a Money in #{currency} by a Money in #{divisor.currency}."
      end
    else
      return calc { amount / divisor }
    end
  end

  # Multiplies this `Money` instance by `multiplier` and returns a new `Money`.
  #
  #     Money.new(2, 'USD') * 2 # => #<Money amount=4.0 currency="USD">
  #
  # @param [~to_d] multiplier
  #   The multiplier, which must be coerced into a `BigDecimal`.
  # @return [Money]
  #   A `Money` instance with amount the result of multiplying and the same currency.
  # @raise [ArgumentError]
  #  Raised if `multiplier` cannot be coerced into a `BigDecimal`.
  def *(multiplier)
    return calc { amount * multiplier }
  end

  # Raises this `Money` instance to the power of `power`, returning a new `Money`.
  #
  #     Money.new(2, 'USD') ** 5 # => #<Money amount=32.0 currency="USD">
  #
  # @param [~to_d] power
  #   The power to raise the amount to.
  # @return [Money]
  #   A `Money` instance with amount the result of raising and with the same currency.
  # @raise [ArgumentError]
  #   Raised if `power` cannot be coerced into a `BigDecimal`.
  def **(power)
    return calc { (amount.to_f ** power).to_d }
  end

  # Returns a `Money` representing the absolute value of this monetary value.
  #
  #     Money.new(2, 'USD').abs  # => #<Money amount=2 currency="USD">
  #     Money.new(-2, 'USD').abs # => #<Money amount=2 currency="USD">
  #
  # @return [Money] The absolute value.
  def abs
    return self.class.new(amount.abs, currency)
  end

  # Determines whether this `Money` represents no value.
  #
  #     Money.new(0, 'USD').zero?  # => true
  #     Money.new(4, 'GBP').zero?  # => false
  #
  # @return [Boolean] `true` if there is no value.
  def zero?
    return amount.zero?
  end

  # Negates this `Money` instance.
  #
  #     -Money.new(5, 'USD') # => #<Money amount=-5 currency="USD">
  #
  # @return [Money] The negated value.
  def -@
    return Money.new(-amount, currency)
  end

  # Determines whether this object has mixed currencies.
  #
  # @return [Boolean] Always `false` for `Money` instances.
  def mixed?
    return false
  end

  # Returns a `Money` instance that has zero amount for the given `currency`.
  #
  # @param [String, Currency] currency
  #   The currency of the new `Money`.
  # @return [Money]
  #   A `Money` instance with 0 amount set in the distant past.
  def self.zero(currency)
    new(0, currency)
  end

  # Formats this `Money` according to the given `options`.
  #
  #     fiveUSD = Money.new(5, 'USD')
  #     fiveUSD.to_s                                # => "$5.00"
  #     fiveUSD.to_s(:precision => 0)               # => "$5"
  #
  # @params [Hash] options
  #   Any options taken by `Money::Formatter.format`.
  # @return [String]
  #   A string representation of this `Money`.
  def to_s(options={})
    Money::Formatter.format(self, options)
  end

  # Converts this `Money` instance to a JSON hash.
  #
  #     Money.new(5, 'USD').to_json  # => {"USD": 5, "currency": "USD"}
  #
  # @return [Hash]
  #   A JSON hash representing this `Money`.
  def as_json(*)
    {currency => amount, "currency" => currency}
  end

private

  # Creates a new `Money` instance with the given attributes.
  #
  #     Money.new(10, 'USD')
  #
  # @param [~to_d] amount
  #   Anything that is convertible to a `BigDecimal`, such as a `String`, `Float`, or `Fixnum`.
  # @param [String, Curency] currency
  #   Any valid currency string (e.g. 'USD') or `Currency` object.
  def initialize(amount, currency)
    set_amount(amount)
    set_currency(currency)
  end

  def set_amount(amount)
    @amount = amount.to_d rescue nil
    raise ArgumentError, "#{amount.inspect} could not be coerced into a BigDecimal" unless @amount.is_a?(BigDecimal)
  end

  def set_currency(currency)
    raise ArgumentError, "Expected currency to be a String or Currency, got #{currency.inspect}" unless currency.is_a?(String) or currency.is_a?(Currency)
    @currency = currency.is_a?(Currency) ? currency.name : currency
  end

  def assert_same_currency(other, message=nil)
    if self.currency != other.currency
      message ||= "Expected #{self.currency}, got #{other.currency}"
      raise ArgumentError, message
    end
  end

  def calc
    begin
      return self.class.new(yield, currency)
    rescue TypeError => e
      raise ArgumentError, e.message
    end
  end
end
