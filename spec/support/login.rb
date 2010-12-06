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
end

RSpec.configure do |config|
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
