# Holds a collection of `Money` objects, summing ones of the same currency.
class Money::Bag
  # Adds a `Money` or `Money::Bag` to this `Money::Bag`, returning itself.
  #
  #     bag = Money::Bag.new
  #     bag.add(Money.new(1, 'USD'))  # => #<Money::Bag @moneys={"USD" => #<Money amount=1.0 currency="USD">}>
  #     bag.add(Money.new(2, 'GBP'))  # => #<Money::Bag @moneys={"USD" => #<Money amount=1.0 currency="USD">, "GBP" => #<Money amount=2.0 currency="GBP">}>
  #
  # @param [Money,Money::Bag] other
  #   The `Money`-containing thing to add to this instance.
  # @return [Money::Bag] Returns `self`.
  def add(other)
    case other
    when Money
      moneys[other.currency] += other
    when Money::Bag
      other.moneys.each { |_, money| add(money) }
    end

    return self
  end

  # Gets the `Money` representing the amount given by `currency`.
  #
  #     bag = Money::Bag.new
  #     bag.add(Money.new(1, 'USD'))
  #     bag.add(Money.new(3.50, 'USD'))
  #     bag["USD"]                      # => #<Money amount=4.5 currency="USD">
  #
  # @param [String] currency
  #   The currency to get the amount for.
  # @return [Money]
  #   The `Money` containing the value this `Money::Bag` holds for that currency.
  def [](currency)
    return moneys[currency]
  end

  # Returns all currencies represented in this `Money::Bag`.
  #
  #     Money::Bag.new.add(Money.new(2, 'USD')).currencies  # => ["USD"]
  #
  # @return [Array<String>] An array of currency names.
  def currencies
    return moneys.keys.sort
  end

  # Converts all `Money`s in this `Money::Bag` to the `target_currency` as of `date`.
  #
  #     bag = Money::Bag.new
  #     bag.add(Money.new(5, "USD"))
  #     bag.add(Money.new(5, "GBP"))
  #     bag.convert_to_currency("USD")    # => #<Money amount=15.0 currency="USD">
  #
  # @param [String] target_currency
  #   The name of the currency to convert to.
  # @param [Date] date
  #   The date the amount should be converted as of.
  # @return [Money]
  #   The sum of the converted `Money` amounts.
  def convert_to_currency(target_currency, date = Date.today)
    return moneys.inject(Money.zero(target_currency)) do |sum, (_, money)|
      sum + money.convert_to_currency(target_currency, date)
    end
  end

  # Duplicates this `Money::Bag` and adds `other` to it.
  #
  # @see Money#add
  def +(other)
    return dup.add(other)
  end

  # Duplicates this `Money::Bag` and negates `other` from it.
  #
  # @see Money#add
  def -(other)
    return self + (-other)
  end

  # Duplicates this `Money::Bag` and negates it.
  #
  # @return [Money::Bag] A negated `Money::Bag`.
  def -@
    return map {|currency, money| -money}
  end

  # Duplicates this `Money::Bag` and multiplies it by `multiplier`.
  #
  # @param [~to_d] multiplier
  #   Anything coercible to a `BigDecimal`.
  # @return [Money::Bag]
  #   A `Money::Bag` with `Money`s equal to those in receiver multiplied by `multiplier`.
  def *(multiplier)
    return map {|currency, money| money * multiplier}
  end

  # Duplicates this `Money::Bag` and raises it to `power`.
  #
  # @param [~to_d] power
  #   Anything coercible to a `BigDecimal`.
  # @return [Money::Bag]
  #   A `Money::Bag` with `Money`s equal to those in receiver raised to `power`.
  def **(power)
    return map {|currency, money| money ** power}
  end

  # Duplicates this `Money::Bag` and divides it by `divisor`.
  #
  # @param [~to_d] divisor
  #   Anything coercible to a `BigDecimal`.
  # @return [Money::Bag]
  #   A `Money::Bag` with `Money`s equal to those in receiver divided by `divisor`.
  def /(divisor)
    return map {|currency, money| money / divisor}
  end

  # Duplicates this `Money::Bag` and takes the absolute value of all contains `Money`s.
  #
  # @return [Money::Bag] A collection of positive `Money`s.
  def abs
    return map {|currency, money| money.abs}
  end

  # Checks for equality with another `Money::Bag`. They are considered the same if they
  # have the same amounts for the contained currencies.
  #
  # @param [Money::Bag] other
  #   The `Money::Bag` to compare it to
  # @return [Boolean]
  #   `true` if they share the same `Money`s.
  def ==(other)
    other.is_a?(Money::Bag) &&
    other.currencies == self.currencies &&
    other.currencies.all? {|currency| other[currency] == self[currency]}
  end

  # Checks whether all contained `Money`s are zero.
  #
  # @return [Boolean]
  #   `true` if all contained `Money`s are zero.
  def zero?
    moneys.all? {|_, money| money.zero?}
  end

  # Determines whether this object has mixed currencies.
  #
  # @return [Boolean] Always `true` for `Money::Bag` instances.
  def mixed?
    return true
  end

  # Formats the `Money`s in this `Money::Bag` by first converting them
  # to a single currency given in `options`.
  #
  #     lunch_money = Money::Bag.new.add(Money.new(4, 'USD'))
  #     lunch_money.to_s(:currency => 'USD')    # => "$4.00"
  #     lunch_money.to_s(:currency => 'GBP')    # => "£2.00"
  #
  # When there is only one currency represented in the `Money::Bag`,
  # the currency option may be omitted.
  #
  #     lunch_money.to_s                        # => "$4.00"
  #
  # Multiple currencies will be first converted to whatever currency
  # is specified by the currency option.
  #
  #     lunch_money.add(Money.new(8, 'CAD'))
  #     lunch_money.to_s(:currency => 'USD')    # => "$12.00"
  #
  # Additional options are passed through to `Money#to_s`.
  #
  #     lunch_money.to_s(:currency => 'CAD', :show_currency => true)  # => "CAD $12.00"
  #
  # @param [Hash] options
  #   A hash of options, all of which are optional except for `:currency`,
  #   which is only optional if there is only a single currency.
  # @return [String]
  #   The converted, formatted value of this `Money::Bag`.
  #
  # @see Money#to_s
  def to_s(options={})
    if currencies.size != 1 && options[:currency].nil?
      return '0'
    end

    return convert_to_currency(options[:currency] || currencies.first).to_s(options)
  end

  # Generates a `Money::Bag` with zero value for the given `currency`.
  #
  # @param [String] currency
  #   Any valid currency name (e.g. USD).
  # @return [Money::Bag]
  #   A bag with a single `Money` that is zero in the given `currency`.
  def self.zero(currency)
    new.add(Money.zero(currency))
  end

protected

  def moneys
    @moneys ||= Hash.new { |hash, currency| hash[currency] = Money.zero(currency) }
  end

  def map
    result = dup
    result.moneys.each {|currency, money| result.moneys[currency] = yield(currency, money)}
    return result
  end
end
