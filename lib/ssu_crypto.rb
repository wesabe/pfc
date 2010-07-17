# a copy of the Crypto class used by ssu-service, since it does its crypto differently
# than the PFC Crypto class does. Yuck.
class SsuCrypto
  # encrypts data with the given key. returns a binary data with the
  # unhashed random iv in the first 16 bytes
  def self.encrypt(data, key)
    cipher = OpenSSL::Cipher::Cipher.new("aes-256-cbc")
    cipher.encrypt
    cipher.key = key
    random_iv = cipher.random_iv
    cipher.iv = random_iv
    encrypted = cipher.update(data)
    encrypted << cipher.final
    # add unhashed iv to front of encrypted data
    return random_iv + encrypted
  end

  def self.decrypt(data, key)
    cipher = OpenSSL::Cipher::Cipher.new("aes-256-cbc")
    cipher.decrypt
    cipher.key = key
    cipher.iv = data[0..15] # extract iv from first 16 bytes
    begin
      decrypted = cipher.update(data[16..-1])
      decrypted << cipher.final
    rescue OpenSSL::CipherError => e
      raise e
    end

    return decrypted
  end
end
