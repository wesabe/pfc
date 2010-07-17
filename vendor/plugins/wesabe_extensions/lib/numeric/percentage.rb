class Numeric
  def percent_of(x)
    if x.nonzero?
      (self.to_f / x.to_f) * 100.00
    else
      0.0
    end
  end
end