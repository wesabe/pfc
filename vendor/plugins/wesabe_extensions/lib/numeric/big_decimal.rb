require "bigdecimal/util"

class BigDecimal
  def inspect
    "#{self.to_s}"
  end

  def to_d
    self
  end
end

class Fixnum
  def to_d
    return self.to_s.to_d
  end
end

class NilClass
  def to_d
    return BigDecimal.new("0")
  end
end

