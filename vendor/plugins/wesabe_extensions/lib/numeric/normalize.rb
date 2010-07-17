class Numeric
  
  # Assume that Infinity and NaN should really be zero.
  def normalize
    !respond_to?(:finite?) || finite? ? self : 0.0
  end
  
end