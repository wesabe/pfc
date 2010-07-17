module Stylesheeter
  extend ActiveSupport::Concern

  included do
    helper_method :stylesheets
  end

  module ClassMethods
    attr_reader :stylesheets

    def stylesheet(*names)
      @stylesheets ||= Array.new
      names.each do |n|
        @stylesheets << n
      end
    end
  end

  module InstanceMethods
    private
    def stylesheets
      self.class.stylesheets || []
    end
  end

end
