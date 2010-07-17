require "test/unit"

require "lib/collections/shuffle"

class TestLibCollectionsShuffle < Test::Unit::TestCase
  def setup
    srand 0xDEADBEEF
    @numbers = [1, 2, 3, 4, 5, 6]
  end
  
  def test_shuffle_should_shuffle_elements
    assert_equal([6, 2, 5, 3, 4, 1], @numbers.shuffle)
    @numbers.shuffle!
    assert_equal([2, 4, 1, 6, 3, 5], @numbers)
  end
  
  def test_random_should_return_a_random_element
    assert_equal(6, @numbers.random)
    assert_equal(1, @numbers.random)
    assert_equal(2, @numbers.random)
  end
end
