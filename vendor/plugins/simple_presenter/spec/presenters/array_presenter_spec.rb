require File.dirname(__FILE__) + '/../spec_helper'
require 'json'

class DummyObject
  def to_json
    "{dummy:true}"
  end
end

describe ArrayPresenter do
  context "when converting an array" do
    before(:all) do
      @array = [1,"bob",{:c => 3}]
      @presenter = Controller.new.present(@array)
    end

    it "should return a json array containing the json version of each object" do
      @presenter.to_json.should == %{[1,"bob",{"c":3}]}
    end

    it "should call to_json on objects in the array" do
      @array << DummyObject.new
      @presenter.to_json.should == %{[1,"bob",{"c":3},{dummy:true}]}
    end
  end

  context "when converting a hash" do
    before(:all) do
      @hash = {1 => "bob", 2 => :c}
      @presenter = Controller.new.present(@hash)
    end

    it "should return a json hash containing the json version of each object" do
      @presenter.to_json.should == %{{"1":"bob","2":"c"}}
    end

    it "should call to_json on objects in the hash" do
      @hash.merge!(3 => DummyObject.new)
      @presenter.to_json.should == %{{"1":"bob","2":"c","3":{dummy:true}}}
    end
  end
end
