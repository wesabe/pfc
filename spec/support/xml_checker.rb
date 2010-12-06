require "xml/libxml"

module Spec
  module Matchers

    class XmlChecker #:nodoc:
      def initialize
        @messages = ""
      end

      def matches?(actual)
        @actual = actual.respond_to?(:body) ? actual.body : actual
        if @actual.blank?
          @messages = "error: No document specified."
          return false
        end
        XML::Error.set_handler{ |x| @messages << x }
        document = XML::Parser.string(@actual).parse
        XML::Error.set_handler(&XML::Error::VERBOSE_HANDLER)
        return @messages.empty?
      rescue XML::Error
        return false
      end

      def messages
        @messages.split("\n").map { |m| "  -> #{m}" }.join("\n")
      end

      def failure_message
        return "#{@actual.inspect} was expected to be well-formed XML, was not well-formed:\n#{messages}\n\n"
      end

      def negative_failure_message
        return "#{@actual.inspect} was expected to not be well-formed XML, but it was well-formed"
      end

      def description
        "be well-formed XML"
      end
    end

    # :call-seq:
    #   should be_well_formed_xml
    #   should_not be_well_formed_xml
    #
    # Passes if actual is well-formed XML
    def be_well_formed_xml
      Matchers::XmlChecker.new
    end
  end
end