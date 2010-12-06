def contain_same_elements_as(expected)
  ContainSameElementsAs.new(expected)
end

class ContainSameElementsAs
  def initialize(expected)
    @expected = expected
  end

  def matches?(actual)
    @actual = actual
    return false if @actual.size != @expected.size

    actual_remainder, expected_remainder = Array(@actual.dup), Array(@expected.dup)
    while expected_remainder.any?
      if index = actual_remainder.index(expected_remainder.pop)
        actual_remainder.delete_at(index)
      end
    end

    return actual_remainder.empty?
  end

  def failure_message
    "expected #{@expected.inspect} to contain the same elements as #{@actual.inspect}"
  end

  def negative_failure_message
    "expected #{@expected.inspect} not to contain the same elements as #{@actual.inspect}"
  end
end

def be_sorted
  BeSorted.new(true)
end

def be_sorted_descending
  BeSorted.new(false)
end

class BeSorted
  def initialize(ascending)
    @ascending = ascending
  end

  def matches?(actual)
    @actual = actual
    return @ascending ? (@actual.sort == @actual) : (@actual.sort == @actual.reverse)
  end

  def failure_message
    "expected #{@actual.inspect} to be sorted"
  end

  def negative_failure_message
    "expected #{@actual.inspect} not to be sorted"
  end
end