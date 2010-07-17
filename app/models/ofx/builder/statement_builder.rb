module OFX
  module Builder
    class StatementBuilder
      attr_accessor :unrecognized_elements # any unrecognized elements that builders come across can be dumped here

      def initialize(statement)
        @statement = statement
        @unrecognized_elements = []
      end

      def add_unrecognized_element(element)
        # don't bother if the element doesn't have content
        if element.content?
          @unrecognized_elements << element
        end
      end
    end
  end
end
