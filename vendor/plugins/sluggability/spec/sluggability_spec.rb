$KCODE = "utf-8"
require "rubygems"
require "spec"
$: << File.dirname(__FILE__) + "/../lib"
require "sluggability"

describe Sluggability, "generating slugs from text" do
  
  def slug(data)
    Sluggability.make_slug(data)
  end
  
  it "should convert characters to lowercase" do
    slug('UPPERCASE').should == 'uppercase'
  end
  
  it "should convert multibyte characters to lowercase" do
    slug('ØŒЛЭ').should == 'øœлэ'
  end
  
  it "should strip all characters which aren't letters, numbers, or dashes" do
    slug('a#(*)#(*@!!)__asdk90').should == 'a-asdk90'
  end
  
  it "should convert an ampersand to 'and'" do
    slug('bobby & susey').should == 'bobby-and-susey'
  end
  
  it "should convert spaces to dashes" do
    slug("one two three").should == "one-two-three"
  end
  
  it "should other whitespace to dashes" do
    slug("one\ttwo\nthree").should == "one-two-three"
  end
  
  it "should compact multiple dashes to single dashes" do
    slug("blah --- blah ---- blah").should == "blah-blah-blah"
  end
  
  it "should compact multiple spaces to single dashes" do
    slug("blah     blah      blah").should == "blah-blah-blah"
  end
  
  it "should trim dashes, spaces, and underscores from the beginning and end of the slug" do
    slug("  blah  ").should == "blah"
    slug("--blah--").should == "blah"
    slug("__blah__").should == "blah"
    slug(" _-blah-_ ").should == "blah"
  end
  
  it "should strip apostrophes" do
    slug("Arby's").should == "arbys"
  end
  
end