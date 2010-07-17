# class to generate a Wesabe "standard" UID
class UID
  LENGTH = 10

  def self.generate(length = LENGTH)
    ActiveSupport::SecureRandom.hex(length)
  end
end
