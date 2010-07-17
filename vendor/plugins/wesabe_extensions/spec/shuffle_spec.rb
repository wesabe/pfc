require "rubygems"
require "spec"
require "../lib/collections/shuffle"

describe "pulling a random element out of an Array" do
  it "should handle arrays of more than 256 elements" do
    OpenSSL::Random.should_receive(:random_bytes).with(4).and_return("\0\1\0\0") # 256
    ((["Y"] * 255) + ["N"]*2).random.should == "N"
  end

  it "should return nil if the array is empty" do
    [].random.should be_nil
  end
end
