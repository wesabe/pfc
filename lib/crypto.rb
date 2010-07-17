class Crypto
  # CipherError moves in ruby 1.8.6 → 1.8.7, this works for both versions
  OpenSSLCipherError = OpenSSL::Cipher.const_defined?(:CipherError) ? OpenSSL::Cipher::CipherError : OpenSSL::CipherError

  # encrypts data with the given key. returns a binary data with the
  # unhashed random iv in the first 16 bytes
  def self.encrypt(data, key)
    cipher = OpenSSL::Cipher::Cipher.new("aes-256-cbc")
    cipher.encrypt
    cipher.key = key = Digest::SHA256.digest(key)
    random_iv = cipher.random_iv
    cipher.iv = Digest::SHA256.digest(random_iv + key)[0..15]
    encrypted = cipher.update(data)
    encrypted << cipher.final
    # add unhashed iv to front of encrypted data
    return random_iv + encrypted
  end

  def self.decrypt(data, key)
    cipher = OpenSSL::Cipher::Cipher.new("aes-256-cbc")
    cipher.decrypt
    cipher.key = cipher_key = Digest::SHA256.digest(key)
    random_iv = data[0..15] # extract iv from first 16 bytes
    data = data[16..data.size-1]
    cipher.iv = Digest::SHA256.digest(random_iv + cipher_key)[0..15]
    begin
      decrypted = cipher.update(data)
      decrypted << cipher.final
    rescue OpenSSLCipherError, TypeError
      return nil
    end

    return decrypted
  end
end