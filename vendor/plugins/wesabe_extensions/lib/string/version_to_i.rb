class String
  # convert a dotted version string to an integer so we can compare
  def version_to_i
    sum = 0
    self.split('.').reverse.each_with_index {|n,i| sum += n.to_i*(100**i) }
    return sum
  end  
end