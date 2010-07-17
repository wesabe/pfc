begin # try rubygems first
  require 'rubygems'
  gem 'activesupport'
  require 'active_support/vendor/builder-2.1.2/blankslate'
rescue
  require 'active_support/vendor/builder-2.1.2/blankslate'
end

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "../lib"))
require 'simple_presenter'


# dummy controller to call #present on
class Controller
  include SimplePresenter::Helper
end

# dummy class to present
class ArrayChild < Array
end

# dummy presenters to test against
class FixnumArrayPresenter < ArrayPresenter
  def sum
    presentable.inject(0){|s,n| s + n }
  end
end

class ArrayChildPresenter < SimplePresenter
end

class StringPresenter < SimplePresenter
  def ascii_numbers
    # returns an array of the integer number each char in the string represents
    presentable.unpack("c*")
  end

  def ascii_numbers_on_self
    # returns the same array but calls unpack on self
    unpack("c*")
  end
end

# unhide some methods so we can test the presentery proxy classes
[:should, :should_not, :instance_of?, :inspect, :class].each do |sym|
  [ SimplePresenter,
    StringPresenter,
    ArrayPresenter,
    ArrayChildPresenter,
    FixnumArrayPresenter
  ].each{|p| p.reveal(sym) }
end
