module OFX
  class Parser
    class XMLParseException < Exception; end

    def initialize(xml, &block)
      @parser = XML::SaxParser.new
      @parser.string = xml
      @parser.callbacks = SaxHandler.new(block)
    end

    def self.parse(xml, &block)
      new(xml, &block).parse
    end

    def parse
      @parser.parse
    end

    class SaxHandler
      include XML::SaxParser::Callbacks

      attr_accessor :elements

      def initialize(block = nil)
        @block = block
        @elements = []
        @path = []
      end

      def on_start_element(element, attributes)
        @path << element
        @elements << OFX::Element.new(@path)
      end

      def on_characters(characters = '')
        @elements.last.content << characters
      end

      def on_end_element(element)
        element = @elements.last
        element.finalize!
        @block.call(element) if @block
        @path.pop
        @elements.pop
      end

      def on_error(msg)
        raise XMLParseException.new(msg)
      end
    end
  end
end