require "test/unit"

require "lib/numeric/sign"

class TestLibNumericSign < Test::Unit::TestCase
  def test_should_compute_sign_of_numbers
    assert_equal(-1, -100.sign)
    assert_equal(-1, (-100.00).sign)
    assert_equal(1, 100.sign)
    assert_equal(1, (100.00).sign)
    assert_equal(0, 0.sign)
    assert_equal(0, (0.00).sign)
  end
end
