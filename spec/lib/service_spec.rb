require 'spec_helper'

describe Service do
  before do
    @logger = stub(:logger, :warn => nil, :error => nil, :debug => nil, :info => nil)
    Service.stub!(:logger).and_return(@logger)
    @service = Service.new('http://example.com/service', 'Basic')
  end

  it "accepts a uri and auth scheme as constructor arguments" do
    @service.base_uri.to_s.should == 'http://example.com/service/'
    @service.auth_scheme.should == 'Basic'
  end

  it "issues get requests" do
    stub_request(:get, 'example.com/service/').
      to_return(:body => 'test response')
    @service.get('/').body.should == 'test response'
  end

  it "appends the given path to the base URI" do
    stub_request(:get, 'example.com/service/users')
    @service.get('/users').body
    request(:get, 'example.com/service/users').should have_been_made.once
  end

  it "returns HTTP errors as normal responses" do
    stub_request(:get, 'example.com/service/').
      to_return(:body => 'OH NOES', :status => [500, 'Internal Server Error'])
    @service.get('/').code.should == 500
  end

  it "can retry a specific number of times" do
    stub_request(:get, 'example.com/service/').to_timeout
    @service.get('/') { |req| req.retries = 2 }
    request(:get, 'example.com/service/').should have_been_made.times(3)
  end
end