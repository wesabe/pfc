require 'spec_helper'

describe Crypto do
  it "should have specs"

  it "should return nil if decryption raises a TypeError" do
    # sometimes we get "can't convert nil into String" from OpenSSL::Cipher::Cipher#update
    @cipher = mock("cipher", :null_object => true)
    @cipher.should_receive(:update).and_raise(TypeError)
    OpenSSL::Cipher::Cipher.stub!(:new).and_return(@cipher)
    Crypto.decrypt("123456789abcdefgthisissomedata", "i'mthecookiemonster").should be_nil
  end
end