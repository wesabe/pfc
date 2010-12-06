module JsonMatchers
  def match_insecure_json(expected)
    MatchJSON.new(expected)
  end

  def match_json(expected)
    MatchSecureJSON.new(expected)
  end

  class MatchJSON
    class MatchError < RuntimeError; end

    def initialize(expected)
      @expected = convert(expected)
    end

    def matches?(actual)
      @actual = convert(actual)
      begin
        self.class.match!(@expected, @actual)
        return true
      rescue MatchError => ex
        @message = ex.message
        return false
      end
    end

    def failure_message
      "expected #{@expected.inspect} but got #{@actual.inspect}\ninner mismatch: #{@message}"
    end

    def negative_failure_message
      "expected not to get #{@expected.inspect} but did"
    end

    def self.match!(expected, actual)
      case expected
      when Rspec::Mocks::ArgumentMatchers::HashIncludingMatcher
        expected.instance_variable_get('@expected').each do |k,v|
          match!(v, actual[k])
        end
      when Hash
        raise MatchError, "Expected #{print(actual)} to be a Hash" unless actual.is_a?(Hash)
        unmatched = (actual.keys - expected.keys) + (expected.keys - actual.keys)
        raise MatchError, "Hash keys differ, unmatched=#{print(unmatched)}" if unmatched.any?

        expected.each do |k,v|
          match!(v, actual[k])
        end
      when Array
        raise MatchError, "Expected #{print(actual)} to be an Array" unless actual.is_a?(Array)
        raise MatchError, "Expected #{expected.size} item(s), but got #{actual.size}" unless (actual.size == expected.size)
        expected.zip(actual).each do |e,a|
          match!(e, a)
        end
      when Proc
        raise MatchError, "#{print(actual)} failed a custom test" unless expected[actual]
      else
        if [expected, actual].any? {|value| value.acts_like?(:date) || value.acts_like?(:time) }
          raise MatchError, "#{print(expected)} != #{print(actual)}" unless dates_equal?(expected, actual)
        else
          raise MatchError, "#{print(expected)} != #{print(actual)}" if expected != actual
        end
      end
    end

  private

    def convert(value)
      case value
      when String
        ActiveSupport::JSON.decode(value)
      when Hash, Array, Rspec::Mocks::ArgumentMatchers::HashIncludingMatcher
        value
      else
        raise ArgumentError, "Unable to generate a JSON value from #{self.class.print(value)}"
      end
    end

    def self.dates_equal?(expected, actual)
      if expected == actual
        true
      elsif expected.acts_like?(:date)
        expected.to_date == actual.to_date
      elsif expected.acts_like?(:time)
        expected.to_time == actual.to_time
      else
        expected.to_date == actual.to_date
      end
    end

    def self.print(object, with_class=false)
      result = object.description rescue object.inspect
      result << " (#{object.class})" if with_class
      result
    end
  end

  class MatchSecureJSON < MatchJSON
    SECURE_PREFIX = "/*-secure- " unless defined?(SECURE_PREFIX)
    SECURE_SUFFIX = " */" unless defined?(SECURE_SUFFIX)

    def matches?(actual)
      @actual = actual
      actual.starts_with?(SECURE_PREFIX) && actual.ends_with?(SECURE_SUFFIX) &&
        super(actual[SECURE_PREFIX.size..(-1-SECURE_SUFFIX.size)])
    end

    def failure_message
      if not @actual.starts_with?(SECURE_PREFIX)
        return "expected #{@actual.inspect} to start with #{SECURE_PREFIX.inspect}"
      elsif not @actual.ends_with(SECURE_SUFFIX)
        return "expected #{@actual.inspect} to end with #{SECURE_SUFFIX.inspect}"
      end if @actual.is_a?(String)

      super
    end

    def negative_failure_message
      if @actual.starts_with?(SECURE_PREFIX)
        return "expected #{@actual.inspect} not to start with #{SECURE_PREFIX.inspect}"
      elsif @actual.ends_with(SECURE_SUFFIX)
        return "expected #{@actual.inspect} not to end with #{SECURE_SUFFIX.inspect}"
      end if @actual.is_a?(String)

      super
    end
  end
end

RSpec.configure do |config|
  config.include(JsonMatchers)
end
