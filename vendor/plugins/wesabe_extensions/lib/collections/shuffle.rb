require 'openssl'

# from the Ruby Cookbook
class Array
  def shuffle!
    each_index do |i|
      j = ::Kernel.rand(length-i) + i
      self[j], self[i] = self[i], self[j]
    end
  end

  def shuffle
    dup.shuffle!
  end

  # Returns a random element from the array.
  def random
    self[ OpenSSL::Random.random_bytes(4).unpack("L")[0] % self.size ] if self.size > 0
  end
end
