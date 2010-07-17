require 'spec_helper'

describe TagParser do
  it "should parse a string of tags into tag names" do
    tag_list = %{one:-10 two "three", "four, five":+10, 'six seven' "eight's nine:100", ten, eleven:1/3 twelve:15.5% "  "}
    tags = TagParser.parse(tag_list)
    tags.length.should == 9
    tags[0].should == "one:-10"
    tags[1].should == "two"
    tags[2].should == "three"
    tags[3].should == "four, five:+10"
    tags[4].should == "six seven"
    tags[5].should == "eight's nine:100"
    tags[6].should == "ten"
    tags[7].should == "eleven:1/3"
    tags[8].should == "twelve:15.5%"
  end

  it "should parse a comma-separated list of tags with no quotes" do
    tag_list = "parking ticket, berkeley, green bananas:6.75"
    tags = TagParser.parse(tag_list)
    tags.length.should == 3
    tags[0].should == "parking ticket"
    tags[1].should == "berkeley"
    tags[2].should == "green bananas:6.75"
  end

  it "should parse a comma-separated list of tags with quotes" do
    tag_list = '"parking ticket", berkeley, green bananas:6.75'
    tags = TagParser.parse(tag_list)
    tags.length.should == 4
    tags[0].should == "parking ticket"
    tags[1].should == "berkeley"
    tags[2].should == "green"
    tags[3].should == "bananas:6.75"
  end

  it "should not include blank tags in the parsed list" do
    TagParser.parse(",foo").should == ["foo"]
  end

  it "should parse splits" do
    TagParser.calculate_split("one").should == nil
    TagParser.calculate_split("one:").should == nil
    TagParser.calculate_split("one:-10").should == 10.0
    TagParser.calculate_split("one:10").should == 10.0
    TagParser.calculate_split("one:-10", -100).should == -10.0
    TagParser.calculate_split("one:6.75", -100).should == -6.75
    TagParser.calculate_split("one:50%", -100).should == -50.0
    TagParser.calculate_split("one:1/2", -100).should == -50.0
    TagParser.calculate_split("one:(1+2+3)*4", 100).should == 24.0
    TagParser.calculate_split("one:2+.77", 100).should == 2.77
  end
end
