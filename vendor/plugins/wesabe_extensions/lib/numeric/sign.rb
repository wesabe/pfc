class Numeric
  def sign
    if zero?
      0
    elsif self < 0
      -1
    else
      1
    end
  end
end

# Fix BigDecimal's more catholic ideas of sign.
class BigDecimal
  def sign
    if zero?
      0
    elsif self < 0
      -1
    else
      1
    end
  end
end