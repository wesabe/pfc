module ActiveRecord
  module ConnectionAdapters # :nodoc:
    class MysqlAdapter
      def quote_with_classes(value, column = nil)
        quote_without_classes(value.is_a?(Class) ? value.to_s : value, column)
      end
      alias_method_chain :quote, :classes
    end
  end
end