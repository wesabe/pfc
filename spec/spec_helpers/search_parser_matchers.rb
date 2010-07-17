module SearchParserMatchers
  class QueryFor
    def initialize(term)
      @term = term
    end

    def matches?(parser)
      @parser = parser
      @parser.query == @term
    end

    def failure_message
      %{expected parser to have query for "#{@term}" but got query "#{@parser.query}"}
    end

  end

  def query_for(term)
    QueryFor.new(term)
  end

  class FilterOn
    def initialize(name, value)
      case value
      when Range
        if value.begin.respond_to?(:to_d) && value.end.respond_to?(:to_d)
          value = value.begin.to_d..value.end.to_d
        end
      end

      @filter = {name => value}
    end

    def matches?(parser)
      @parser = parser
      @parser.filters.include?(@filter)
    end

    def failure_message
      %{expected parser to filter on #{@filter.inspect}, but it filtered on #{@parser.filters.inspect}}
    end
  end

  def filter_on(name, value)
    FilterOn.new(name, value)
  end
end