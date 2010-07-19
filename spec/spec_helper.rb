# This file is copied to ~/spec when you run 'ruby script/generate rspec'
# from the project root directory.
ENV["RAILS_ENV"] ||= 'test'
require File.dirname(__FILE__) + "/../config/environment" unless defined?(Rails)
require 'rspec/autorun'
require 'rspec/rails'

# Uncomment the next line to use webrat's matchers
#require 'webrat/integrations/rspec-rails'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir[File.expand_path(File.join(File.dirname(__FILE__),'support','**','*.rb'))].each {|f| require f}

# load Machinist blueprints
require 'blueprints'

require 'webmock/rspec'
include WebMock

Rspec.configure do |config|
  WebMock.disable_net_connect!

  def clear_currency_exchange_rates
    CurrencyExchangeRate.delete_all
    Rails.cache.clear
  end

  def exist(file)
    simple_matcher "existing file" do
      if file.respond_to?(:exist?)
        file.exist?
      else
        File.exist?(file)
      end
    end
  end

  def fixture_file_upload(name)
    File.open("spec/fixtures/#{name}")
  end

  shared_examples_for "it has a logged-in user" do

    def current_user
      @current_user ||= User.make
      User.current = @current_user
    end

    before(:each) do
      current_user # set User.current

      if @controller
        @controller.stub!(:check_authentication).and_return(true)
        @controller.stub!(:current_user).and_return(current_user)
        @controller.stub!(:clear_current_user_global)
      end
    end
    # FIXME: is it possible to automatically generate specs for the converse condition?
    # (i.e. if something requires an admin user, it should fail if the user is not an admin)
  end

  shared_examples_for "it has an admin user" do
    it_should_behave_like "it has a logged-in user"
    before(:each) do
      current_user.admin = true
      current_user.save!
      if @controller
        @controller.stub!(:check_for_admin).and_return(true)
        @controller.stub!(:current_user).and_return(current_user)
      end
    end
    # FIXME: is it possible to automatically generate specs for the converse condition?
    # (i.e. if something requires an admin user, it should fail if the user is not an admin)
  end

  # NOTE: Prevent sweeping so that we can test flash.now
  # see http://blog.peelmeagrape.net/2008/5/21/rspec-testing-flash-in-rails-controller-specs
  config.before(:each, :behaviour_type => :controller) do
    @controller.instance_eval { flash.stub!(:sweep) } if @controller
  end

  config.after(:each) do
    User.current = nil
    Rails.cache.clear
  end

end

# gather all exemplars from spec/exemplars
Dir[File.join(File.dirname(__FILE__), 'exemplars', '*.rb')].each do |file|
  if File.basename(file) =~ %r{(.*)_exemplar.rb}
    $1.classify.constantize.gather_exemplars
  end
end

# load all files from spec/spec_helpers/*
Dir[File.join(File.dirname(__FILE__), "spec_helpers", "**", "*.rb")].each do |f|
  require f
end

Rspec.configure do |config|
  config.include(ActiveRecordMatchers)
  config.include(SearchParserMatchers)
  config.include(JsonMatchers)
end

module ActionController
  class Base
    def rescue_action(exception)
      raise exception
    end
  end

  class TestResponse
    def created?
      status == 201
    end

    def bad_request?
      status == 400
    end

    def unauthorized?
      status == 401
    end

    def forbidden?
      status == 403
    end

    def not_found?
      status == 404
    end

    def method_not_allowed?
      status == 405
    end

    def not_acceptable?
      status == 406
    end

    def unprocessable_entity?
      status == 422
    end

    def error?
      status == 500
    end

    def post_only?
      method_not_allowed? && headers["Allow"] == "POST"
    end

    def get_only?
      method_not_allowed? && headers["Allow"] == "GET"
    end

    def redirected_to_login?
      redirect? && redirected_to == "http://test.host/user/login"
    end
  end
end

class FakeFileUpload
  attr_accessor :original_filename, :size, :content_type, :read

  def initialize(filename, size, content_type, data)
    @original_filename, @size, @content_type, @read = filename, size, content_type, data
  end

  def length
    @read.size
  end
end

class Test::Unit::TestCase

  def load_fixture_image(fixture)
    data = File.open(File.join(File.dirname(__FILE__), 'fixtures', 'images', fixture)).binmode.read
    return FakeFileUpload.new(fixture, data.size, "image/#{File.extname(fixture).downcase}", data)
  end

  def users_with_account_key(user)
    user = users(user) unless user.is_a?(User)
    # test user passwords must be the same as the username
    return user.authenticated_by(user.username)
  end

  def login(user = :first)
    @user = users_with_account_key(user)
    @request.session[:user] = @user.id
    @request.session[:expires_at] = 20.minutes.from_now
    @request.session[:account_key] = @user.account_key
  end

  def self.should_bounce_to_login(options)
    method, action, options = __parse_options(options)

    it "should redirect to the login page if the user is not logged in" do
      controller.should_receive(:check_authentication).with(no_args).and_return { controller.redirect_to :controller => "sessions", :action => "new" }
      controller.should_not_receive(action)
      send(method, action, *options)
    end
  end

  def self.should_return_method_not_allowed(options)
    method, action, options = __parse_options(options)

    it "should return a 405 error on #{method.to_s.upcase}" do
      controller.should_receive(:check_authentication).with(no_args).once.and_return(true)

      send(method, action, *options)

      response.should be_method_not_allowed
      response.headers['Allow'].should_not eql(method.to_s.upcase)
    end
  end

private

  def self.__parse_options(options)
    method = options.keys.first
    action = options[method]

    if action.respond_to?(:values)
      options = [action.values.first]
      action = action.keys.first
    else
      options = []
    end

    return method, action, options
  end
end

module SetReferrer
  def set_referrer(path)
    @request.stub!(:env).and_return({"HTTP_REFERER" => path})
  end

  def set_intended(uri)
    @request.session[:intended_uri] = uri
  end
end

# redefine DJ's delay method so that we can test
class Object
  def delay
    self
  end
end
