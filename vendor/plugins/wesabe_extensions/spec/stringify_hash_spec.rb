require "rubygems"
require "spec"
require "lib/collections/stringify_hash"

describe "stringifying a Hash" do   
  it "should return the same result regardless of hash order or key type" do
    foo = {:a => 1, :b=> 2, :c => 3, 7 => 42}
    bar = {"b"=> 2, :c => 3, "7" => 42, :a => 1}
    foo.to_s.should_not == bar.to_s
    foo.stringify.should == bar.stringify
  end
end