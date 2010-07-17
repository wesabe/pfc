$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + "/../lib"))
require "rubygems"
require "spec"
require "date/parse"

describe "parsing a date" do
  it "should raise an exception if the year is out of range" do
    lambda {Date.parse("20087-01-12")}.should raise_error(ArgumentError)
  end
  
  it "should not raise an exception if the year is not out of range" do
    lambda {Date.parse("2008-01-12")}.should_not raise_error(ArgumentError)
  end
end