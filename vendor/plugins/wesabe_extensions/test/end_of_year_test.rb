require "test/unit"

require "lib/time/end_of_year"

class TestLibTimeEndOfYear < Test::Unit::TestCase
  def test_should_return_end_of_year
    assert_equal(Time.mktime(2007, 12, 31, 23, 59, 59), Time.mktime(2007, 4, 11).end_of_year)
  end
end