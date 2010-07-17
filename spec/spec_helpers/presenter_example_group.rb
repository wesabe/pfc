module PresenterExampleGroup
  extend ActiveSupport::Concern

  include RSpec::Rails::SetupAndTeardownAdapter
  include RSpec::Rails::TestUnitAssertionAdapter
  include ActionView::TestCase::Behavior
  include RSpec::Rails::ViewAssigns
  include Webrat::Matchers

  module ClassMethods
    def determine_default_presenter_class(ignore)
      describes
    end
  end

  module InstanceMethods
    # Returns an instance of the presenter under test.
    # def presenter
    #   @presenter ||= described_class.new
    # end

  private

    # def _controller_path
    #   example.example_group.describes.to_s.sub(/Presenter/,'').underscore
    # end
  end

  included do
    before do
      PresenterBase.view = _view
    end
  end

  RSpec.configure do |c|
    c.include self, :example_group => { :file_path => %r{\bspec/presenters/} }
  end
end