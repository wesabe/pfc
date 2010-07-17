require "test/unit"

require "lib/time/end_of_day"

class TestLibTimeEndOfDay < Test::Unit::TestCase
  def test_should_return_the_last_second_of_the_day
    assert_equal("Tue Apr 14 23:59:59 -0800 1981", Time.parse('4/14/81 8:00PM').end_of_day.to_s)
    assert_equal("Tue Apr 14 23:59:59 -0800 1981", Time.parse('4/14/81 8:00PM').end_of_day.end_of_day.to_s)
  end
end