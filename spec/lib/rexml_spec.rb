require 'spec_helper'

##
# AUTHORS: Geoffrey Grosenbach http://nubyonrails.com
#          Also http://p.ramaze.net/1887
#
# INSTALLATION:
#          Copy to spec/lib/rexml_spec.rb, or any subdirectory of "spec"
#
# RUN:
#   spec spec/lib/rexml_spec.rb
#
#   Or, just run your specs as usual.


describe REXML do

  it "handles DOS vulnerability" do
    # From http://p.ramaze.net/1887
    dom = REXML::Document.new('<?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE member [
      <!ENTITY a "&b;&b;&b;&b;&b;&b;&b;&b;&b;&b;">
      <!ENTITY b "&c;&c;&c;&c;&c;&c;&c;&c;&c;&c;">
      <!ENTITY c "&d;&d;&d;&d;&d;&d;&d;&d;&d;&d;">
      <!ENTITY d "&e;&e;&e;&e;&e;&e;&e;&e;&e;&e;">
      <!ENTITY e "&f;&f;&f;&f;&f;&f;&f;&f;&f;&f;">
      <!ENTITY f "&g;&g;&g;&g;&g;&g;&g;&g;&g;&g;">
      <!ENTITY g "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx">
    ]>
    <member>
    &a;
    </member>')

    lambda {
      dom.root.elements.to_a('//member').first.text
    }.should raise_error(RuntimeError, "Number of entity expansions exceeded, processing aborted.")
  end

end