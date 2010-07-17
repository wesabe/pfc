$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + "/../lib"))
require "rubygems"
require "spec"
require "collections/all_the_same"


describe "method all_the_same?" do
  it "should return true if all the items in the array are the same" do
    ["A", "A"].should be_all_the_same
  end
  
  it "should return false if the array has non-identical items" do
    ["A", "B"].should_not be_all_the_same
  end
end