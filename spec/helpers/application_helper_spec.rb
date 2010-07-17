require 'spec_helper'

describe ApplicationHelper, "internal referrer" do
  include ApplicationHelper

  before do
    @request = mock("request")
  end

  it "should return a hash of the route parameters" do
    set_referrer "http://www.wesabe.com/accounts/1"
    internal_referer.should == {:controller => "accounts", :action => "show", :id => "1"}
  end

  it "should not return a hash if the hostname is not wesabe.com in production" do
    set_referrer "http://www.google.com/accounts/1"
    silence_warnings { RAILS_ENV = "production" }
    internal_referer.should be_nil
    silence_warnings { RAILS_ENV = "test" }
  end

  it "should return a hash if the hostname is not wesabe.com but RAILS_ENV is not production" do
    set_referrer "http://www.google.com/accounts/1"
    internal_referer.should == {:controller => "accounts", :action => "show", :id => "1"}
  end

  it "should not return a hash if the protocol is wrong" do
    set_referrer "ftp://www.wesabe.com/accounts/1"
    internal_referer.should be_nil
  end

  it "should return a hash if the protocal is https" do
    set_referrer "https://www.wesabe.com/accounts/1"
    internal_referer.should == {:controller => "accounts", :action => "show", :id => "1"}
  end

  it "should not return a hash if the route only accepts POST" do
    set_referrer "http://www.wesabe.com/preferences/user_preferences"
    internal_referer.should be_nil
  end

  it "should not return a hash if the format is xml, xls, csv, qif, ofx, ofx2" do
    %w(xml xls csv qif ofx ofx2).each do |f|
      set_referrer "https://www.wesabe.com/accounts/1.#{f}"
      internal_referer.should be_nil
    end
  end

  include SetReferrer
end

describe ApplicationHelper, "link_to_url" do
  before do
    @url = 'https://www.wesabe.com/groups/3-make-wesabe-better/discussions/1453-anybody-use-texans-credit-union-successfully-with-automatic-uploads'
  end

  it "should omit the protocol when rendering the link" do
    helper.link_to_url('http://www.google.com/').should have_tag('a', 'www.google.com/')
    helper.link_to_url('https://www.wesabe.com').should have_tag('a', 'www.wesabe.com')
  end

  it "should truncate the url to 30 characters" do
    helper.link_to_url(@url).should have_tag('a', 'www.wesabe.com/groups/3-mak...')
  end

  it "should omit script tags" do
    helper.link_to_url("http://malicious.com/?<script>sekret.send()</script>").should_not have_tag('script')
  end

  it "should not render a link when url is blank" do
    helper.link_to_url(nil).should be_blank
    helper.link_to_url('').should be_blank
    helper.link_to_url('  ').should be_blank
  end
end